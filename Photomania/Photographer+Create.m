//
//  Photographer+Create.m
//  Photomania
//
//  Created by 刘芳芳 on 16/11/16.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "Photographer+Create.h"

@implementation Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photographer *photographer = nil;
    
    if([name length]) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
        
        NSError *error;
        NSArray *matches = [context executeFetchRequest:request error:&error];
        
        if(!matches || error || ([matches count] > 1)) {
            //handler error
        }else if (![matches count]) {
            photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer" inManagedObjectContext:context];
            photographer.name = name;
        }else {
            photographer = [matches firstObject];
        }

    }
    
    return photographer;
}
@end
