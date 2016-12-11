//
//  Photo+Annotation.m
//  Photomania
//
//  Created by 刘芳芳 on 16/12/11.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "Photo+Annotation.h"

@implementation Photo (Annotation)

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    
    coordinate.latitude = [self.latitude doubleValue];
    coordinate.longitude = [self.longitude doubleValue];
    
    return coordinate;
}

@end
