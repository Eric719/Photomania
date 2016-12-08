//
//  Photo+Flickr.m
//  Photomania
//
//  Created by 刘芳芳 on 16/11/15.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "Photographer+Create.h"

@implementation Photo (Flickr)
+ (Photo *)photoWithFlicrkInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = nil;
    
    NSString *unique = photoDictionary[FLICKR_PHOTO_ID];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", unique];
    
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    
    if(!matches || error || ([matches count] > 1)) {
        //handler error
    }else if ([matches count]) {
        photo = [matches firstObject];
    }else {
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo"
                                              inManagedObjectContext:context];
        photo.unique = unique;
        photo.title = [photoDictionary valueForKeyPath:FLICKR_PHOTO_TITLE];
        photo.subtitle = [photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.imageURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        NSString *photographerName = [photoDictionary valueForKeyPath:FLICKR_PHOTO_OWNER];
        photo.whoTook = [Photographer photographerWithName:photographerName inManagedObjectContext:context];
    }
    
    return photo;
}

+ (void)loadPhotoFromFlickrArray:(NSArray *)photos //of flickr NSDictionay
        intoManagedObjectContext:(NSManagedObjectContext *)context
{
    for (NSDictionary *photo in photos){
        [self photoWithFlicrkInfo:photo
           inManagedObjectContext:context];
    }
}
@end
