//
//  CreateEventFriendPickerViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/11/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

NSString * const kFBGraphUserIdKey = @"id";

#import "CreateEventFriendPickerViewController.h"
#import "CreateEventModel.h"

@interface CreateEventFriendPickerViewController () <FBFriendPickerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) CreateEventModel *createEventModel;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSString *searchText;

@property (nonatomic, strong) NSTimer *refreshTimer;

- (void)cancel:(id)sender;

@end

@implementation CreateEventFriendPickerViewController

- (id)initWithEventModel:(CreateEventModel *)createEventModel
{
    self = [super init];
    if (self) {
        
        self.createEventModel = createEventModel;
        
        self.delegate = self;
        self.title = @"Invite Friends";
        
        self.navigationItem.hidesBackButton = YES;
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:nil];
        self.doneButton = doneButton;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self loadData];
    
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search friends";
    self.searchBar.autocapitalizationType = YES;
    
    NSMutableDictionary *viewsDict = [[NSMutableDictionary alloc] initWithDictionary:@{ @"searchBar":self.searchBar }];
    
    
    
    [self.view addSubview:self.searchBar];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDict]];
    
    [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewsDict addEntriesFromDictionary:@{ @"tableView":self.tableView }];
    
    [self.view addSubview:self.tableView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar][tableView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDict]];
}

- (void)handleSearchWithoutResign:(id)sender
{
    self.searchText = self.searchBar.text;
    [self updateView];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
    if (self.refreshTimer) {
        [self.refreshTimer invalidate];
    }
    
    self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:0.7
                                                         target:self
                                                       selector:@selector(handleSearchWithoutResign:)
                                                       userInfo:nil
                                                        repeats:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self.searchBar resignFirstResponder];
    [self handleSearchWithoutResign:nil];
}

- (BOOL)friendPickerViewController:(FBFriendPickerViewController *)friendPicker
                 shouldIncludeUser:(id<FBGraphUser>)user
{
    if (self.searchText && ![self.searchText isEqualToString:@""]) {
        
        NSRange result = [user.name
                          rangeOfString:self.searchText
                          options:NSCaseInsensitiveSearch];
        if (result.location != NSNotFound) {
            return YES;
        } else {
            return NO;
        }
        
    } else {
        return YES;
    }
    return YES;
}

- (void)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    NSMutableArray *invitedFriends = [[NSMutableArray alloc] init];
    for (FBGraphObject *user in self.selection) {
        [invitedFriends addObject:user[kFBGraphUserIdKey]];
    }
    self.createEventModel.invitedFriendIds = [NSArray arrayWithArray:invitedFriends];
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
