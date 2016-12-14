//
//  Photographer+Create.h
//  Photomania
//
//  Created by 刘芳芳 on 16/11/16.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "Photographer.h"

@interface Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name
                inManagedObjectContext:(NSManagedObjectContext *)context;

+ (Photographer *)userInManagedObjectContext:(NSManagedObjectContext *)context;

- (BOOL)isUser;

@end
