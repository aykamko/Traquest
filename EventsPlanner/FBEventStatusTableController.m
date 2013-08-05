//
//  FBEventTableViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/5/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "FBEventStatusTableController.h"
#import "FBEventStatusViewDataSource.h"
#import "ParseDataStore.h"

@interface FBEventStatusTableController () <UITableViewDelegate>

@property (nonatomic, copy) void (^completionBlock)(NSString *newStatus);
@property (nonatomic, strong) FBEventStatusViewDataSource *dataSource;
@property (nonatomic, strong) UITableViewController *tableViewController;

@property (nonatomic, strong) UITableViewCell *selectedCell;

- (void)changeStatus;
- (void)cancelView;

@end

@implementation FBEventStatusTableController

- (id)initWithStatus:(NSString *)status completion:(void (^)(NSString *newStatus))completionBlock
{
    self = [super init];
    if (self) {
        
        _completionBlock = completionBlock;
        _dataSource = [[FBEventStatusViewDataSource alloc] init];
        
        _tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[_tableViewController tableView] setDelegate:self];
        [[_tableViewController tableView] setDataSource:_dataSource];
        [_tableViewController setTitle:@"RSVP Status"];
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(changeStatus)];
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancelView)];
        
        [_tableViewController.navigationItem setRightBarButtonItem:doneButton];
        [_tableViewController.navigationItem setBackBarButtonItem:cancelButton];
        [_tableViewController.navigationController.navigationBar setTranslucent:NO];
        
        NSIndexPath *indexPath;
        if ([status isEqualToString:@"attending"]) {
            indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
            [[[self tableViewController] tableView] selectRowAtIndexPath:indexPath
                                                                animated:YES
                                                          scrollPosition:UITableViewScrollPositionNone];
            [self tableView:[[self tableViewController] tableView] didSelectRowAtIndexPath:indexPath];
        } else if ([status isEqualToString:@"unsure"]) {
            indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
            [[[self tableViewController] tableView] selectRowAtIndexPath:indexPath
                                                                animated:YES
                                                          scrollPosition:UITableViewScrollPositionNone];
            [self tableView:[[self tableViewController] tableView] didSelectRowAtIndexPath:indexPath];
        } else {
            indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
            [[[self tableViewController] tableView] selectRowAtIndexPath:indexPath
                                                                animated:NO
                                                          scrollPosition:UITableViewScrollPositionNone];
            [self tableView:[[self tableViewController] tableView] didSelectRowAtIndexPath:indexPath];
        }
        
    }
    return self;
}

- (UIViewController *)presentableViewController
{
    return [self tableViewController];
}

- (void)changeStatus
{
    NSString *selectedCellString = [[_selectedCell textLabel] text];
    _completionBlock(selectedCellString);
    
    [_tableViewController.navigationController popViewControllerAnimated:YES];
}

- (void)cancelView
{
    [_tableViewController.navigationController popViewControllerAnimated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Clear old selection
    if (_selectedCell)
        [_selectedCell setAccessoryType:UITableViewCellAccessoryNone];
    
    // Update to new selection
    _selectedCell = [[_tableViewController tableView] cellForRowAtIndexPath:indexPath];
    [_selectedCell setAccessoryType:UITableViewCellAccessoryCheckmark];
    
}

@end
