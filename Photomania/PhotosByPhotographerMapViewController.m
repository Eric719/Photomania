//
//  PhotosByPhotographerMapViewController.m
//  Photomania
//
//  Created by 刘芳芳 on 16/12/11.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "PhotosByPhotographerMapViewController.h"
#import <Mapkit/Mapkit.h>
#import "Photo+Annotation.h"
#import "ImageViewController.h"
#import "Photographer+Create.h"
#import "AddPhotoViewController.h"

@interface PhotosByPhotographerMapViewController () <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) NSArray *photosByPhotographer;
@property (nonatomic, strong) ImageViewController *imageViewController;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addPhotoBarButtonItem;
@end

@implementation PhotosByPhotographerMapViewController

- (ImageViewController *)imageViewController
{
    id detailvc = [self.splitViewController.viewControllers lastObject];
    if([detailvc isKindOfClass:[UINavigationController class]]){
        detailvc = [((UINavigationController *)detailvc).viewControllers firstObject];
    }
    return [detailvc isKindOfClass:[ImageViewController class]] ? detailvc : nil;
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    static NSString *reuseId = @"PhotosByPhotographerMapViewController";
    MKAnnotationView *view = [mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
    if (!view){
        view = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        view.canShowCallout = YES;
        if(!self.imageViewController){
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 46, 46)];
            view.leftCalloutAccessoryView = imageView;
            UIButton *disclosureButton = [[UIButton alloc] init];
            [disclosureButton setBackgroundImage:[UIImage imageNamed:@"arrow"] forState:UIControlStateNormal];
            [disclosureButton sizeToFit];
            view.rightCalloutAccessoryView = disclosureButton;
        }
    }
    
    view.annotation = annotation;
    return view;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view
{
    if(self.imageViewController){
        [self prepareViewController:self.imageViewController
                           forSegue:nil
                   toShowAnnotation:view.annotation];
    }else{
        [self updateLeftCalloutAccessoryViewInAnnotationView:view];
    }
}

//这个会在作何左/右视图中，uibutton被点击里调用，这里就是会在点击右侧箭头是调用，显示全图
- (void)mapView:(MKMapView *)mapView annotationView:(nonnull MKAnnotationView *)view calloutAccessoryControlTapped:(nonnull UIControl *)control
{
    [self performSegueWithIdentifier:@"Show Photo" sender:view];
}

- (void)prepareViewController:(id)vc forSegue:(NSString *)sequeIdentifier toShowAnnotation:(id<MKAnnotation>)annotation
{
    Photo *photo = nil;
    if([annotation isKindOfClass:[Photo class]]){
        photo = (Photo *)annotation;
    }
    if (photo){
        if(![sequeIdentifier length] || [sequeIdentifier isEqualToString:@"Show Photo"]){
            if([vc isKindOfClass:[ImageViewController class]]){
                ImageViewController *ivc = (ImageViewController *)vc;
                ivc.imageURL = [NSURL URLWithString:photo.imageURL];
                ivc.title = photo.title;
            }
        }
    }
}
//unwind时需要调用的方法
- (IBAction)addedPhoto:(UIStoryboardSegue *)segue
{
    if ([segue.sourceViewController isKindOfClass:[AddPhotoViewController class]]){
        AddPhotoViewController *apvc = (AddPhotoViewController *)segue.sourceViewController;
        Photo *addedPhoto = apvc.addedPhoto;
        if(addedPhoto){
            [self.mapView addAnnotation:addedPhoto];
            [self.mapView showAnnotations:@[addedPhoto] animated:YES];
            self.photosByPhotographer = nil;
        }else{
            NSLog(@"AddPhotoViewController unexpectedly did not add a photo!");
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.destinationViewController isKindOfClass:[AddPhotoViewController class]]){
        AddPhotoViewController *apvc = (AddPhotoViewController *)segue.destinationViewController;
        apvc.photographerTakingPhoto = self.photographer;
    }else if([sender isKindOfClass:[MKAnnotationView class]]){
        [self prepareViewController:segue.destinationViewController
                           forSegue:segue.identifier
                   toShowAnnotation:((MKAnnotationView *)sender).annotation];
    }
}

- (void)updateLeftCalloutAccessoryViewInAnnotationView:(MKAnnotationView *)annotationView
{
    UIImageView *imageView = nil;
    if([annotationView.leftCalloutAccessoryView isKindOfClass:[UIImageView class]]){
        imageView = (UIImageView *)annotationView.leftCalloutAccessoryView;
    }
    if(imageView){
        Photo *photo = nil;
        if([annotationView.annotation isKindOfClass:[Photo class]]){
            photo = (Photo *)annotationView.annotation;
        }
        if(photo){
#warning Blocking main queue!
            imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photo.thumbnailURL]]];
        }
    }
}

- (void)updateMapViewAnnotations
{
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView addAnnotations:self.photosByPhotographer];
    [self.mapView showAnnotations:self.photosByPhotographer animated:YES];
    //选中某人后自动选择一张照片，以此来不显示上一个点击人的照片
    if(self.imageViewController){
        Photo *autoSelectedPhoto = [self.photosByPhotographer firstObject];
        if (autoSelectedPhoto){
            [self.mapView selectAnnotation:autoSelectedPhoto animated:YES];
            [self prepareViewController:self.imageViewController
                               forSegue:nil
                       toShowAnnotation:autoSelectedPhoto];
        }
    }
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    self.mapView.delegate = self;
    [self updateMapViewAnnotations];
}

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    self.photosByPhotographer = nil;
    [self updateMapViewAnnotations];
    [self updateAddPhotoBarButtonItem];// show "camera" button only if self.photographer.isUser
}


- (void)updateAddPhotoBarButtonItem
{
    if(self.addPhotoBarButtonItem){
        BOOL canAddPhoto = self.photographer.isUser;
        NSMutableArray *rightBarButtonItems = [self.navigationItem.rightBarButtonItems mutableCopy];
        if(!rightBarButtonItems){
            rightBarButtonItems = [[NSMutableArray alloc] init];
        }
        NSUInteger addPhotoBarButtonItemIndex = [rightBarButtonItems indexOfObject:self.addPhotoBarButtonItem];
        if(addPhotoBarButtonItemIndex == NSNotFound){
            if(canAddPhoto) [rightBarButtonItems addObject:self.addPhotoBarButtonItem];
        }else{
            if(!canAddPhoto) [rightBarButtonItems removeObjectAtIndex:addPhotoBarButtonItemIndex];
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    }
}

- (NSArray *)photosByPhotographer
{
    if (!_photosByPhotographer){
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
        request.predicate = [NSPredicate predicateWithFormat:@"whoTook = %@", self.photographer];
        _photosByPhotographer = [self.photographer.managedObjectContext executeFetchRequest:request error:NULL];
    }
    return _photosByPhotographer;
}

@end
