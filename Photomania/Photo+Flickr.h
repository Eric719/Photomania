//
//  Photo+Flickr.h
//  Photomania
//
//  Created by 刘芳芳 on 16/11/15.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "Photo.h"

@interface Photo (Flickr)

+ (Photo *)photoWithFlicrkInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context;

+ (void)loadPhotoFromFlickrArray:(NSArray *)photo //of flickr NSDictionay
        intoManagedObjectContext:(NSManagedObjectContext *)context;
@end
