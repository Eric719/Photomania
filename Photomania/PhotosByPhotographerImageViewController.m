//
//  PhotosByPhotographerImageViewController.m
//  Photomania
//
//  Created by 刘芳芳 on 16/12/11.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "PhotosByPhotographerImageViewController.h"
#import "PhotosByPhotographerMapViewController.h"

@interface PhotosByPhotographerImageViewController ()

@property (nonatomic,strong) PhotosByPhotographerMapViewController *mapvc;
@end
@implementation PhotosByPhotographerImageViewController

- (void)setPhotographer:(Photographer *)photographer
{
    _photographer = photographer;
    self.title = photographer.name;
    self.mapvc.photographer = self.photographer;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.destinationViewController isKindOfClass:[PhotosByPhotographerMapViewController class]]){
        PhotosByPhotographerMapViewController *pbpmapvc = (PhotosByPhotographerMapViewController *)segue.destinationViewController;
        pbpmapvc.photographer = self.photographer;
        self.mapvc = pbpmapvc;
    }else{
        [super prepareForSegue:segue sender:sender];
    }
}

@end
