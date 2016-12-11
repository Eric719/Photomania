//
//  PhotographersCDTVC.m
//  Photomania
//
//  Created by 刘芳芳 on 16/11/19.
//  Copyright © 2016年 刘芳芳. All rights reserved.
//

#import "PhotographersCDTVC.h"
#import "Photographer.h"
#import "PhotoDatabaseAvailability.h"
#import "PhotosByPhotographerCDTVC.h"
#import "PhotosByPhotographerMapViewController.h"
#import "PhotosByPhotographerImageViewController.h"

@implementation PhotographersCDTVC

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:PhotoDatabaseAvailablilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note){
                                                      self.managedObjectContext = note.userInfo[PhotoDatabaseAvailablilityContext];
                                                  }];
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                    ascending:YES
                                     selector:@selector(localizedStandardCompare:)]];
    //request.fetchLimit = 100;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
        managedObjectContext:managedObjectContext
          sectionNameKeyPath:nil
                   cacheName:nil];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Photographer Cell"];
    Photographer *phtotgrapher =  [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = phtotgrapher.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu photos", [phtotgrapher.photos count]];
    return cell;
}

#pragma mark - Navigation

- (void)prepareViewController:(id)vc forSegue:(NSString *)segueIdentifer fromIndexPath:(NSIndexPath *)indexPath
{
    Photographer *photographer = [self.fetchedResultsController objectAtIndexPath:indexPath];
    NSLog(@"--%@",photographer);
    if([vc isKindOfClass:[PhotosByPhotographerCDTVC class]]) {
        PhotosByPhotographerCDTVC *pbpcdtvc = (PhotosByPhotographerCDTVC *)vc;
        pbpcdtvc.photographer = photographer;
    }else if ([vc isKindOfClass:[PhotosByPhotographerMapViewController class]]){
        PhotosByPhotographerMapViewController *pbpmapvc = (PhotosByPhotographerMapViewController *)vc;
        pbpmapvc.photographer = photographer;
    }else if([vc isKindOfClass:[PhotosByPhotographerImageViewController class]]){
        PhotosByPhotographerImageViewController *pbpivc = (PhotosByPhotographerImageViewController *)vc;
        pbpivc.photographer = photographer;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]){
        indexPath = [self.tableView indexPathForCell:sender];
    }
    [self prepareViewController:segue.destinationViewController
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailvc = [self.splitViewController.viewControllers lastObject];
    //如果是UINavigationController 就去找它的根视图控制器
    if ([detailvc isKindOfClass:[UINavigationController class]]) {
        detailvc = [((UINavigationController *)detailvc).viewControllers firstObject];
        [self prepareViewController:detailvc
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}

@end
