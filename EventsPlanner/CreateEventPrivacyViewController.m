//
//  CreateEventPrivacyViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

NSString * const kPublicPrivacyString = @"Public";
NSString * const kFriendsOfGuestPrivacyString = @"Friends of Guests";
NSString * const kInviteOnlyPrivacyString = @"Invite Only";

#import "CreateEventPrivacyViewController.h"
#import "CreateEventModel.h"

@interface CreateEventPrivacyViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) CreateEventModel *createEventModel;

@property (strong, nonatomic) UITableViewController *privacyTableViewController;
@property (strong, nonatomic) UITableViewCell *selectedCell;

@property (strong, nonatomic) NSArray *privacyTypesArray;

- (void)cancelSetPrivacy:(id)sender;
- (void)setPrivacy:(id)sender;

@end

@implementation CreateEventPrivacyViewController

- (id)initWithEventModel:(CreateEventModel *)createEventModel
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        self.createEventModel = createEventModel;
        
        if (!self.createEventModel.privacyType) {
            _privacyType = kFriendsOfGuestPrivacyString;
            self.createEventModel.privacyType = self.privacyType;
        } else {
            NSString *privacyType = self.createEventModel.privacyType;
            if ([privacyType isEqualToString:@"OPEN"]) {
                _privacyType = kPublicPrivacyString;
            } else if ([privacyType isEqualToString:@"FRIENDS"]) {
                _privacyType = kFriendsOfGuestPrivacyString;
            } else if ([privacyType isEqualToString:@"SECRET"]) {
                _privacyType = kInviteOnlyPrivacyString;
            } else {
                _privacyType = kFriendsOfGuestPrivacyString;
            }
        }
        
        self.privacyTypesArray = @[kPublicPrivacyString, kFriendsOfGuestPrivacyString, kInviteOnlyPrivacyString];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancelSetPrivacy:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(setPrivacy:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        
        self.navigationItem.hidesBackButton = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Select Privacy";
}

#pragma mark Table View Methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _privacyType = self.privacyTypesArray[indexPath.row];
    
    self.selectedCell.accessoryType = UITableViewCellAccessoryNone;
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.selectedCell = cell;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:nil];
    
    cell.textLabel.text = self.privacyTypesArray[indexPath.row];
    
    if ([cell.textLabel.text isEqualToString:self.privacyType]) {
        self.selectedCell = cell;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.privacyTypesArray count];
}
#pragma mark Privacy Methods
- (void)cancelSetPrivacy:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setPrivacy:(id)sender
{
    self.createEventModel.privacyType = self.privacyType;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
