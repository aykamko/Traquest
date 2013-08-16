//
//  CreateEventPlacePickerViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/12/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "CreateEventPlacePickerViewController.h"
#import "CreateEventModel.h"
#import "ParseDataStore.h"
#import "GraphicsConstants.h"

NSString * const kLocationIdPlacePickerKey = @"id";
NSString * const kLocationNamePlacePickerKey = @"name";

@interface CreateEventPlacePickerViewController () <FBPlacePickerDelegate, UISearchBarDelegate>

@property (nonatomic, strong) CreateEventModel *createEventModel;

@property (nonatomic, strong) UISearchBar *searchBar;

@property (nonatomic, strong) UIView *placeHolderView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@property (nonatomic, strong) NSTimer *refreshTimer;

- (void)cancel:(id)sender;

@end

@implementation CreateEventPlacePickerViewController

- (id)initWithEventModel:(CreateEventModel *)createEventModel
{
    self = [super init];
    if (self) {
        
        self.createEventModel = createEventModel;
        
        self.delegate = self;
        self.title = @"Add Place";
        
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

- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor orangeColor];
    
    self.searchBar = [[UISearchBar alloc] init];
    [self.searchBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search a place";
    self.searchBar.autocapitalizationType = YES;
    
    NSMutableDictionary *viewsDict = [[NSMutableDictionary alloc] initWithDictionary:@{ @"searchBar":self.searchBar }];
    
    [self.view addSubview:self.searchBar];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[searchBar]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDict]];
    
    self.placeHolderView = [[UIView alloc] init];
    [self.placeHolderView setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.placeHolderView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    [viewsDict addEntriesFromDictionary:@{ @"placeHolderView":self.placeHolderView }];
    
    [self.view addSubview:self.placeHolderView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[placeHolderView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar][placeHolderView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewsDict]];
    
    // Setting up spinner
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewsDict addEntriesFromDictionary:@{ @"spinner":self.spinner }];
    
    UILabel *loadingLabel = [[UILabel alloc] init];
    [loadingLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewsDict addEntriesFromDictionary:@{ @"loadingLabel":loadingLabel }];
    loadingLabel.text = @"Getting your location...";
    loadingLabel.textColor = [UIColor darkTextColor];
    
    CGRect addedRect = self.spinner.bounds;
    addedRect.size.width += loadingLabel.bounds.size.width + kStandardMargin;
    
    UIView *spinnerWrapperView = [[UIView alloc] initWithFrame:addedRect];
    [viewsDict addEntriesFromDictionary:@{ @"spinnerWrapperView":spinnerWrapperView }];
    [spinnerWrapperView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    spinnerWrapperView.backgroundColor = [UIColor clearColor];
    
    [spinnerWrapperView addSubview:self.spinner];
    [spinnerWrapperView addSubview:loadingLabel];
    [spinnerWrapperView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[spinner]-[loadingLabel]|"
                                                                               options:0
                                                                               metrics:0
                                                                                 views:viewsDict]];
    [spinnerWrapperView addConstraint:[NSLayoutConstraint constraintWithItem:self.spinner
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:spinnerWrapperView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0]];
    [spinnerWrapperView addConstraint:[NSLayoutConstraint constraintWithItem:loadingLabel
                                                                   attribute:NSLayoutAttributeCenterY
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:spinnerWrapperView
                                                                   attribute:NSLayoutAttributeCenterY
                                                                  multiplier:1.0
                                                                    constant:0.0]];
    
    [self.placeHolderView addSubview:spinnerWrapperView];
    [self.placeHolderView addConstraint:[NSLayoutConstraint constraintWithItem:spinnerWrapperView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.placeHolderView
                                                                     attribute:NSLayoutAttributeCenterX
                                                                    multiplier:1.0
                                                                      constant:0.0]];
    [self.placeHolderView addConstraint:[NSLayoutConstraint constraintWithItem:spinnerWrapperView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.placeHolderView
                                                                     attribute:NSLayoutAttributeCenterY
                                                                    multiplier:1.0
                                                                      constant:0.0]];
    [self.spinner startAnimating];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[ParseDataStore sharedStore] fetchLocationWithCompletion:^(CLLocation *location) {
        
        self.locationCoordinate = [location coordinate];
        [self loadData];
        
        [self.tableView setTranslatesAutoresizingMaskIntoConstraints:NO];
        NSDictionary *loadedViewsDict = @{ @"tableView":self.tableView,
                                           @"searchBar":self.searchBar };
        
        [self.placeHolderView removeFromSuperview];
        self.placeHolderView = nil;
        
        [self.view addSubview:self.placeHolderView];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tableView]|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:loadedViewsDict]];
        
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[searchBar][tableView]|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:loadedViewsDict]];
    }];
}
#pragma  mark Search Bar Methods
- (void)handleSearchWithoutResign:(id)sender
{
    if ([self.searchBar.text isEqualToString:@""]) {
        self.searchText = nil;
    } else {
        self.searchText = self.searchBar.text;
    }
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
#pragma mark Place Picker
- (BOOL)placePickerViewController:(FBPlacePickerViewController *)placePicker
               shouldIncludePlace:(id<FBGraphPlace>)place
{
    if (self.searchText && ![self.searchText isEqualToString:@""]) {
        
        NSRange result = [place.name
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
#pragma mark cancel method
- (void)cancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark Facebook Button Pressed Done
- (void)facebookViewControllerDoneWasPressed:(id)sender
{
    self.createEventModel.locationId = self.selection[kLocationIdPlacePickerKey];
    self.createEventModel.location = self.selection[kLocationNamePlacePickerKey];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
