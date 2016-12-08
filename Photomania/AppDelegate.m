//
//  AppDelegate.m
//  Photomania
//
//  Created by 刘芳芳 on 16/11/14.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "AppDelegate.h"
#import "PhotomaniaAppDelegate+MOC.h"
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"
#import "PhotoDatabaseAvailability.h"

@interface AppDelegate () <NSURLSessionDownloadDelegate>
@property (copy, nonatomic) void (^flickrDownloadBackgroundURLSessionCompletionHandler)();
@property (strong, nonatomic) NSURLSession *flickrDownloadSession;
@property (strong, nonatomic) NSTimer *flickrForegroundFetchTimer;
@property (strong, nonatomic) NSManagedObjectContext *photoDatabaseContext;

@end

//name of the Flickr fetching background download session
#define FLICKR_FETCH @"Flickr just Uploaded fetch"

//how often (in seconds) we fetch new photos if we are in foreground
#define FOREGROUND_FLICKR_FETCH_INTERVAL (20 * 60)

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.photoDatabaseContext = [self createMainQueueManagedObjectContext];
    [self startFlickrFetch];
    return YES;
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [self startFlickrFetch];
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    self.flickrDownloadBackgroundURLSessionCompletionHandler = completionHandler;
}

- (void)setPhotoDatabaseContext:(NSManagedObjectContext *)photoDatabaseContext
{
    _photoDatabaseContext = photoDatabaseContext;
    
    [NSTimer scheduledTimerWithTimeInterval:20*60
                                     target:self
                                   selector:@selector(startFlickrFetch:)
                                   userInfo:nil
                                    repeats:YES];//前台取回时使用
    
    NSDictionary *userInfo = self.photoDatabaseContext ? @{ PhotoDatabaseAvailablilityContext:self.photoDatabaseContext } : nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:PhotoDatabaseAvailablilityNotification object:self userInfo:userInfo];
}

- (void)startFlickrFetch:(NSTimer *)timer
{
    [self startFlickrFetch];
}

//this might not word if we are in background (discretionary), but that's okay
- (void)startFlickrFetch
{
    [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        // let's see if we're already working on a fetch ...
        if (![downloadTasks count]) {
            // ... not working on a fetch, let's start one up
            NSURLSessionDownloadTask *task = [self.flickrDownloadSession downloadTaskWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
            task.taskDescription = FLICKR_FETCH;
            [task resume];
        } else {
            // ... we are working on a fetch (let's make sure it (they) is (are) running while we're here)
            for (NSURLSessionDownloadTask *task in downloadTasks) [task resume];
        }
    }];
}

- (NSURLSession *)flickrDownloadSession
{
    if (!_flickrDownloadSession) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfiguration:FLICKR_FETCH];
            urlSessionConfig.allowsCellularAccess = NO; //for example
            _flickrDownloadSession = [NSURLSession sessionWithConfiguration:urlSessionConfig
            delegate:self
       delegateQueue:nil];
        });
    }
    return _flickrDownloadSession;
}

- (NSArray *)flickrPhotosAtURL:(NSURL *)url
{
    NSData *flickrJSONData = [NSData dataWithContentsOfURL:url];
    NSDictionary *flickrPropertyList = [NSJSONSerialization JSONObjectWithData:flickrJSONData
                                                                       options:0
                                                                         error:NULL];
    return [flickrPropertyList valueForKeyPath:FLICKR_RESULTS_PHOTOS];
}

//ready by the protocol
- (void)URLSession:(NSURLSession *)session
      downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(nonnull NSURL *)location
{
    if ([downloadTask.taskDescription isEqualToString:FLICKR_FETCH]) {
        NSManagedObjectContext *context = self.photoDatabaseContext;
        if(context) {
            NSArray *photos = [self flickrPhotosAtURL:location];
            [context performBlock:^{
                [Photo loadPhotoFromFlickrArray:photos intoManagedObjectContext:context];
                [context save:NULL];
            }];
        }else {
            [self flickrDownloadTaskMightBeComplete];
        }
    }
}

//required by the protocol 文件刚完成下载时
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    
}

//required by the protocol 是否分块来读
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{

}

- (void)flickrDownloadTaskMightBeComplete
{
    if(self.flickrDownloadBackgroundURLSessionCompletionHandler){
        [self.flickrDownloadSession getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downTasks){
            if (![downTasks count]) {// no more download left ?
                void (^completHandler)() = self.flickrDownloadBackgroundURLSessionCompletionHandler;
                self.flickrDownloadBackgroundURLSessionCompletionHandler = nil;
                if(completHandler) {
                    completHandler();
                }
            }
        }];
    }
}

@end
