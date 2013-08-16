//
//  CreateEventTimePickerViewController.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/10/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "CreateEventTimePickerViewController.h"
#import "CreateEventModel.h"
#import "GraphicsConstants.h"
#import "NSDate+ExtraStuff.h"

static NSIndexPath * kStartTimeCellIndexPath;
static NSIndexPath * kEndTimeCellIndexPath;
static NSIndexPath * kAllDayCellIndexPath;

NSString * const kStartTimeCellLabelText = @"Start";
NSString * const kEndTimeCellLabelText = @"End";
NSString * const kEndTimeCellOptionalText = @"Optional";
NSString * const kAllDayCellLabelText = @"All Day";

@interface CreateEventTimePickerViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) CreateEventModel *createEventModel;
@property (nonatomic, strong) NSMutableDictionary *mutableEventTimeDict;

@property (nonatomic, strong) UITableView *timeDetailTableView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UISwitch *allDaySwitch;

@property (nonatomic, strong) NSIndexPath *selectedCellIndexPath;

- (void)updateTimeInSelectedCell:(id)sender;
- (void)setAllDayEvent:(id)sender;

- (void)cancelSetTime:(id)sender;
- (void)setTimeInfo:(id)sender;

@end

@implementation CreateEventTimePickerViewController

- (id)initWithEventModel:(CreateEventModel *)createEventModel
{
    self = [super init];
    if (self) {
        
        self.createEventModel = createEventModel;
        self.mutableEventTimeDict = [[NSMutableDictionary alloc]
                              initWithDictionary:@{ kStartTimeEventParameterKey:
                                                        [NSDate dateToNearestFifteenMinutes:[NSDate date]] }];
        self.createEventModel.startTime = self.mutableEventTimeDict[kStartTimeEventParameterKey];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancelSetTime:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(setTimeInfo:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        
        self.navigationItem.hidesBackButton = YES;
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Select Time";
}

- (void)viewDidAppear:(BOOL)animated
{
    //TODO: find out a way to select this earlier
    [super viewDidLayoutSubviews];
    [self.timeDetailTableView selectRowAtIndexPath:kStartTimeCellIndexPath
                                          animated:NO
                                    scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.timeDetailTableView didSelectRowAtIndexPath:kStartTimeCellIndexPath];
}

- (void)loadView
{
    // Adding base view
    [super loadView];
    self.view = [[UIView alloc] init];
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    
    // Initializing views dictionary for autolayout
    NSMutableDictionary *viewDict = [[NSMutableDictionary alloc] init];
    
    // Adding date picker
    self.datePicker = [[UIDatePicker alloc] init];
    [self.datePicker setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewDict addEntriesFromDictionary:@{ @"datePicker":self.datePicker }];
    
    [self.datePicker setMinuteInterval:5];
    [self.datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
    [self.datePicker addTarget:self
                        action:@selector(updateTimeInSelectedCell:)
              forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:self.datePicker];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[datePicker]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewDict]];
    // Adding table view
    self.timeDetailTableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                            style:UITableViewStyleGrouped];
    [self.timeDetailTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [viewDict addEntriesFromDictionary:@{ @"timeDetailTableView":self.timeDetailTableView }];
    
    [self.timeDetailTableView setDataSource:self];
    [self.timeDetailTableView setDelegate:self];
    
    [self.view addSubview:self.timeDetailTableView];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[timeDetailTableView]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewDict]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[timeDetailTableView][datePicker]|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:viewDict]];
}
#pragma mark Table View Methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.allDaySwitch.isOn) {
        return 2;
    } else {
        return 3;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                   reuseIdentifier:nil];
    [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:kDefaultTableCellFontSize]];
    
    
    NSInteger row = indexPath.row;
    if (row == 0) {
        
        cell.textLabel.text = kStartTimeCellLabelText;
        cell.detailTextLabel.text =
            [NSDate prettyReadableStringFromDate:self.mutableEventTimeDict[kStartTimeEventParameterKey]];
        
        kStartTimeCellIndexPath = indexPath;
        
    } else if (row == 1) {
        
        cell.textLabel.text = kEndTimeCellLabelText;
        
        if (self.mutableEventTimeDict[kEndTimeEventParameterKey]) {
            cell.detailTextLabel.text =
                [NSDate prettyReadableStringFromDate:self.mutableEventTimeDict[kEndTimeEventParameterKey]];
        } else {
            cell.detailTextLabel.text = kEndTimeCellOptionalText;
        }
        
        kEndTimeCellIndexPath = indexPath;
        
    } else if (row == 2) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:nil];
        [[cell textLabel] setFont:[UIFont boldSystemFontOfSize:kDefaultTableCellFontSize]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = kAllDayCellLabelText;
        
        self.allDaySwitch = [[UISwitch alloc] init];
        [self.allDaySwitch addTarget:self
                              action:@selector(setAllDayEvent:)
                    forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = self.allDaySwitch;
        
        kAllDayCellIndexPath = indexPath;
        
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedCellIndexPath = indexPath;
    
    if ([self.selectedCellIndexPath compare:kAllDayCellIndexPath] == NSOrderedSame) {
        return;
    }
    
    if ([self.selectedCellIndexPath compare:kStartTimeCellIndexPath] == NSOrderedSame) {
        
        [self.datePicker setDate:(NSDate *)self.mutableEventTimeDict[kStartTimeEventParameterKey]];
        
    } else if ([self.selectedCellIndexPath compare:kEndTimeCellIndexPath] == NSOrderedSame) {
    
        if (!self.mutableEventTimeDict[kEndTimeEventParameterKey]) {
            
            NSDate *datePlusThreeHours = [NSDate
                                          dateWithTimeInterval:3 * 60 * 60
                                          sinceDate:self.mutableEventTimeDict[kStartTimeEventParameterKey]];
            
            self.mutableEventTimeDict[kEndTimeEventParameterKey] = datePlusThreeHours;
            
            UITableViewCell *endTimeCell = [self.timeDetailTableView cellForRowAtIndexPath:kEndTimeCellIndexPath];
            endTimeCell.detailTextLabel.text =
                [NSDate prettyReadableStringFromDate:self.mutableEventTimeDict[kEndTimeEventParameterKey]];
            
        }
        
        [self.datePicker setDate:(NSDate *)self.mutableEventTimeDict[kEndTimeEventParameterKey]];
        
    }
}

#pragma mark Timer Methods

- (void)updateTimeInSelectedCell:(id)sender
{
    if ([self.selectedCellIndexPath compare:kAllDayCellIndexPath] == NSOrderedSame) {
        return;
    }
    
    UITableViewCell *cell = [self.timeDetailTableView cellForRowAtIndexPath:self.selectedCellIndexPath];
    
    if ([self.selectedCellIndexPath compare:kStartTimeCellIndexPath] == NSOrderedSame) {
        
        self.mutableEventTimeDict[kStartTimeEventParameterKey] = self.datePicker.date;
        
    } else if ([self.selectedCellIndexPath compare:kEndTimeCellIndexPath] == NSOrderedSame) {
        
        self.mutableEventTimeDict[kEndTimeEventParameterKey] = self.datePicker.date;
        
    }
    
    cell.detailTextLabel.text = [NSDate prettyReadableStringFromDate:self.datePicker.date];
}

- (void)setAllDayEvent:(id)sender
{
    UISwitch *allDaySwitch = (UISwitch *)sender;
    UITableViewCell *endTimeCell = [self.timeDetailTableView cellForRowAtIndexPath:kEndTimeCellIndexPath];
    
    //TODO: figure out all day events
    if (endTimeCell) {
        if (allDaySwitch.isOn) {
            [self.timeDetailTableView deleteRowsAtIndexPaths:@[kEndTimeCellIndexPath]
                                            withRowAnimation:UITableViewRowAnimationBottom];
        } else {
            [self.timeDetailTableView insertRowsAtIndexPaths:@[kEndTimeCellIndexPath]
                                            withRowAnimation:UITableViewRowAnimationBottom];
        }
    }
}

- (void)cancelSetTime:(id)sender
{
    self.mutableEventTimeDict = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setTimeInfo:(id)sender
{
    self.createEventModel.startTime = self.mutableEventTimeDict[kStartTimeEventParameterKey];
    if (self.mutableEventTimeDict[kEndTimeEventParameterKey]) {
        self.createEventModel.endTime = self.mutableEventTimeDict[kEndTimeEventParameterKey];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end