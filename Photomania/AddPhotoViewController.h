//
//  AddPhotoViewController.h
//  Photomania
//
//  Created by 刘芳芳 on 16/12/13.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Photographer.h"
#import "Photo.h"

@interface AddPhotoViewController : UIViewController

//in
@property (nonatomic, strong) Photographer *photographerTakingPhoto;

//out
@property (nonatomic, readonly) Photo *addedPhoto;

@end
