//
//  AddPhotoViewController.m
//  Photomania
//
//  Created by 刘芳芳 on 16/12/13.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "AddPhotoViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+CS193p.h"

@interface AddPhotoViewController () <UITextFieldDelegate, UIAlertViewDelegate, CLLocationManagerDelegate, UINavigationControllerDelegate,UIImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UITextField *subtitleTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) UIImage *image;
@property (strong, nonatomic) CLLocation *location;
@property (strong, nonatomic) NSURL *imageURL;
@property (strong, nonatomic) NSURL *thumbnailURL;
@property (strong, nonatomic, readwrite) Photo *addedPhoto;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSInteger locationErrorCode;
@end

@implementation AddPhotoViewController

+ (BOOL)canAddPhoto
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]){
        NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        if([availableMediaTypes containsObject:(NSString *)kUTTypeImage]){
            if([CLLocationManager authorizationStatus] != kCLAuthorizationStatusRestricted){
                return YES;
            }
        }
    }
    return NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.locationManager startUpdatingLocation];
    
    if(![[self class] canAddPhoto]){
        [self fatalAlert:@"Sorry, this device cannot take a photo."];
    }else {
        [self.locationManager startUpdatingLocation];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.image = [UIImage imageNamed:@"haer.jpg"];
}

#define UNWIND_SEGUE_IDENTIFIER @"Do Add Photo"

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]){
        NSManagedObjectContext *context = self.photographerTakingPhoto.managedObjectContext;
        if(context){
            Photo *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
            photo.title = self.titleTextField.text;
            photo.subtitle = self.subtitleTextField.text;
            photo.whoTook = self.photographerTakingPhoto;
            photo.latitude = @(self.location.coordinate.latitude);
            photo.longitude = @(self.location.coordinate.longitude);
            photo.imageURL = [self.imageURL absoluteString];
            photo.thumbnailURL = [self.thumbnailURL absoluteString];
            
            self.addedPhoto = photo;
            
            self.imageURL = nil;//this url has been used now
            self.thumbnailURL = nil;
        }
    }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:UNWIND_SEGUE_IDENTIFIER]){
        if(!self.image){
            [self alert:@"No photo taken!"];
            return NO;
        }else if (![self.titleTextField.text length]){
            [self alert:@"Title required!"];
            return NO;
        }else if(!self.location){//如果没有获得位置
            switch (self.locationErrorCode) {
                case kCLErrorLocationUnknown:
                    [self alert:@"Could't figure out where this photo was taken (yet)."];
                    break;
                case kCLErrorDenied:
                    [self alert:@"Location Server disabled under Privacy in Settings application."];break;
                case kCLErrorNetwork:
                    [self alert:@"Can't figure out where this photo is being taken. Verify your connection to network."];break;
                default:
                    [self alert:@"Can't figure out where this photo	is being taken, sorry"];break;
            }
            return NO;
        }else{
            return YES;
        }
    }else{
        return [super shouldPerformSegueWithIdentifier:identifier sender:sender];
    }
}

- (void)alert:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:@"Add Photo"
                                message:msg
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (void)fatalAlert:(NSString *)msg
{
    [[[UIAlertView alloc] initWithTitle:@"Add Photo"
                                message:msg
                               delegate:self
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self cancel];
}

- (CLLocationManager *)locationManager
{
    if(!_locationManager) {
        CLLocationManager *locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;//把精度设为最佳
        _locationManager = locationManager;
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(nonnull NSArray<CLLocation *> *)locations
{
    self.location = [locations lastObject];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    self.locationErrorCode = error.code;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (NSURL *)uniqueDocumentURL
{
    NSArray *documentDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSString *unique = [NSString stringWithFormat:@"%.0f", floor([NSDate timeIntervalSinceReferenceDate])];
    return [[documentDirectories firstObject] URLByAppendingPathComponent:unique];
}

- (NSURL *)imageURL
{
    if (!_imageURL && self.image){
        NSURL *url = [self uniqueDocumentURL];
        if (url){
            NSData *imageData = UIImageJPEGRepresentation(self.image, 1.0);
            if([imageData writeToURL:url atomically:YES]){
                _imageURL = url;
            }
        }
    }
    return _imageURL;
}

- (NSURL *)thumbnailURL
{
    NSURL *url = [self.imageURL URLByAppendingPathExtension:@"thumbnail"];
    if(![_thumbnailURL isEqual:url]){
        _thumbnailURL = nil;
        if(url){
            UIImage *thumbnail = [self.image imageByScalingToSize:CGSizeMake(75, 75)];
            NSData *imageData = UIImageJPEGRepresentation(thumbnail, 0.5);
            if([imageData writeToURL:url atomically:YES]){
                _thumbnailURL = url;
            }
        }
    }
    return _thumbnailURL;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    [[NSFileManager defaultManager] removeItemAtURL:_imageURL error:NULL];
    [[NSFileManager defaultManager] removeItemAtURL:_thumbnailURL error:NULL];
    self.imageURL = nil;
    self.thumbnailURL = nil;
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (IBAction)cancel
{
    self.image = nil;//cleans up any temporary file
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)takePhoto {
    UIImagePickerController *uiipc = [[UIImagePickerController alloc] init];
    uiipc.delegate = self;
    uiipc.mediaTypes = @[(NSString *)kUTTypeImage];
    uiipc.sourceType = UIImagePickerControllerSourceTypeCamera | UIImagePickerControllerSourceTypePhotoLibrary;
    //uiipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;//在模拟器上只能用从照片库中选择，如果使用用上面使用相机选项，会崩溃
    uiipc.allowsEditing = YES;
    [self presentViewController:uiipc animated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];//取用户编辑过的图片
    if(!image) image = info[UIImagePickerControllerOriginalImage];//原始图片
    self.image = image;
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
