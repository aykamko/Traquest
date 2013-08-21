//
//  CheckInTableView.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 8/20/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "CheckInTableView.h"
#import "GraphicsConstants.h"
#import "ParseDataStore.h"

@interface CheckInTableView () <UITextViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) NSString *placeId;
@property (nonatomic, strong) NSString *placeName;

@property (nonatomic, strong) NSString *privacyParam;
@property (nonatomic, weak) UILabel *privacyLabel;

@property (nonatomic, weak) UITextView *textView;

@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)cancel:(id)sender;
- (void)postCheckIn:(id)sender;

@end

@implementation CheckInTableView

- (id)initWithPlace:(NSString *)placeId placeName:(NSString *)placeName
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
        self.placeId = placeId;
        self.placeName = placeName;
        
        [self.tableView setScrollEnabled:NO];
        
        [self setTitle:@"Check In"];
        
        UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                         style:UIBarButtonItemStyleBordered
                                                                        target:self
                                                                        action:@selector(cancel:)];
        self.navigationItem.leftBarButtonItem = cancelButton;
        

        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Post"
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(postCheckIn:)];
        self.navigationItem.rightBarButtonItem = doneButton;
        self.navigationItem.hidesBackButton = YES;
        
        self.privacyParam = @"FRIENDS_OF_FRIENDS";
        
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                     initWithTarget:self
                                     action:@selector(resignKeyboard:)];
        
    }
    return self;
}


- (void)resignKeyboard:(UIGestureRecognizer *)gestureRecognizer
{
    if ([self.textView isFirstResponder]) {
        [self.textView resignFirstResponder];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([textView.text isEqualToString:@""]) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    return YES;
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    [self.tableView addGestureRecognizer:self.tapGestureRecognizer];
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [self.tableView removeGestureRecognizer:self.tapGestureRecognizer];
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        UIActionSheet *privacyActions = [[UIActionSheet alloc] initWithTitle:nil
                                                                    delegate:self
                                                           cancelButtonTitle:@"Cancel"
                                                      destructiveButtonTitle:nil
                                                           otherButtonTitles:@"Everyone",@"Friends of Friends",@"Friends Only",@"Self", nil];
        [privacyActions showInView:self.tableView];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    self.privacyParam = [self stringToPostPrivacyParameter:buttonTitle];
    self.privacyLabel.text = [self postPrivacyParameterToString:self.privacyParam];
    [self.privacyLabel setNeedsDisplay];
}

- (NSString *)postPrivacyParameterToString:(NSString *)privacyParameter
{
    if ([privacyParameter isEqualToString:@"EVERYONE"]) {
        return @"Everyone";
    } else if ([privacyParameter isEqualToString:@"FRIENDS_OF_FRIENDS"]) {
        return @"Friends of Friends";
    } else if ([privacyParameter isEqualToString:@"ALL_FRIENDS"]) {
        return @"Friends Only";
    } else if ([privacyParameter isEqualToString:@"SELF"]) {
        return @"Self";
    } else {
        return nil;
    }
}

- (NSString *)stringToPostPrivacyParameter:(NSString *)privacyString
{
    if ([privacyString isEqualToString:@"Everyone"]) {
        return @"EVERYONE";
    } else if ([privacyString isEqualToString:@"Friends of Friends"]) {
        return @"FRIENDS_OF_FRIENDS";
    } else if ([privacyString isEqualToString:@"Friends Only"]) {
        return @"ALL_FRIENDS";
    } else if ([privacyString isEqualToString:@"Self"]) {
        return @"SELF";
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (indexPath.section == 0) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        
        UITextView *textView = [[UITextView alloc] init];
        [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [textView setFont:[UIFont systemFontOfSize:kDefaultTableCellFontSize]];
        [textView setText:[NSString stringWithFormat:@"I just got to %@!", self.placeName]];
        
        [textView setDelegate:self];
        
        NSDictionary *viewsDict = @{ @"textView": textView };
        [cell.contentView addSubview:textView];
        self.textView = textView;
        
        NSInteger textViewMargin;
        if ([[[UIDevice currentDevice] systemVersion] floatValue] > 6.1) {
            textViewMargin = kTableCellMarginiOS7;
        } else {
            textViewMargin = kTableCellMargin;
        }
        
        NSDictionary *metricsDict = @{ @"margin":[NSNumber numberWithInteger:textViewMargin] };
        
        [cell.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"V:|[textView]|"
                                          options:0
                                          metrics:metricsDict
                                          views:viewsDict]];
        [cell.contentView addConstraints:[NSLayoutConstraint
                                          constraintsWithVisualFormat:@"H:|-(margin)-[textView]-(margin)-|"
                                          options:0
                                          metrics:metricsDict
                                          views:viewsDict]];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
        
    } else if (indexPath.section == 1) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        
        cell.textLabel.text = @"Privacy";
        self.privacyLabel = cell.detailTextLabel;
        cell.detailTextLabel.text = [self postPrivacyParameterToString:self.privacyParam];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        return cell;
        
    } else if (indexPath.section == 2) {
        
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.userInteractionEnabled = NO;
        
        cell.textLabel.textColor = [UIColor lightTextColor];
        cell.textLabel.text = self.placeName;
        
        return cell;
        
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath compare:[NSIndexPath indexPathForRow:0 inSection:0]] == NSOrderedSame) {
        return 200;
    }
    return kDefaultTableCellHeight;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 2) {
        return @"Place";
    }
    return nil;
}

- (void)cancel:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)postCheckIn:(id)sender
{
    __block UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *spinnerBarButton = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    self.navigationItem.rightBarButtonItem = spinnerBarButton;
    [spinner startAnimating];
    
    NSDictionary *privacyDict = @{ @"value": self.privacyParam };
    NSData *privacyJSON = [NSJSONSerialization dataWithJSONObject:privacyDict
                                                          options:NSJSONWritingPrettyPrinted
                                                            error:nil];
    NSDictionary *postDict = @{ @"message": self.textView.text,
                                @"place": self.placeId,
                                @"privacy": [[NSString alloc] initWithData:privacyJSON encoding:NSUTF8StringEncoding] };
    
    [[ParseDataStore sharedStore] postCheckInToEvent:postDict completion:^{
        [spinner stopAnimating];
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }];
    
}

@end
