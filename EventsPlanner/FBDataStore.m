//
//  FBDataStore.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "FBDataStore.h"
#import <Parse/PFUser.h>
#import "UIImage+ImageCrop.h"

@interface FBDataStore(){
    NSMutableArray *_arrayOfEventIds;
}

@end
@implementation FBDataStore

+ (id)allocWithZone:(struct _NSZone *)zone
{
    return [self sharedStore];
}

+ (FBDataStore *)sharedStore
{
    static FBDataStore *sharedStore = nil;
    if (!sharedStore)
        sharedStore = [[super allocWithZone:nil] init];
    
    return sharedStore;
}

- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *hostEvents, NSArray *guestEvents))completionBlock
{
    
    FBRequest *request = [FBRequest requestForGraphPath:
                          @"me?fields=events.limit(1000).fields(name,admins.fields(id,name),"
                          @"attending.limit(5),location,cover,owner,"
                          @"privacy,description,venue,picture,rsvp_status),id"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            NSString *myID = result[@"id"];
            
            // Save the logged in user's Facebook ID to parse
            [[PFUser currentUser] setObject:myID forKey:@"fbID"];
            [[PFUser currentUser] saveInBackground];
            
            FBGraphObject *fbGraphObj = (FBGraphObject *)result;
            NSArray *eventArray = fbGraphObj[@"events"][@"data"];
            NSMutableArray *hostEvents = [[NSMutableArray alloc] init];
            NSMutableArray *guestEvents = [[NSMutableArray alloc] init];
            
            for (FBGraphObject *event in eventArray) {
                
                NSArray *adminArray = event[@"admins"][@"data"];
                
                BOOL isHost = NO;
                for (FBGraphObject *adminData in adminArray) {
                    if ([adminData[@"id"] isEqualToString:myID]) {
                        isHost = YES;
                        break;
                    }
                }
                
                if (isHost == YES) {
                    [hostEvents insertObject:event atIndex:0];
                } else {
                    [guestEvents insertObject:event atIndex:0];
                }
                CGSize defaultCoverSize = {640,320};
                if(!event[@"cover"]) {
                    UIImage *mainImage = [UIImage imageNamed:@"eventCoverPhoto.png"];
                    NSLog(@"%f, %f", mainImage.size.height, mainImage.size.width);
                    UIImage *coloring = [UIImage imageWithBackground:[UIColor colorWithWhite:0 alpha:0.3] size:defaultCoverSize];
                    UIImage *imageWithBackground = [UIImage overlayImage:coloring overImage:mainImage];
                    UIImage *gradientImage = [UIImage imageWithGradient:defaultCoverSize withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] vertical:NO];
                    event[@"cover"] = [UIImage overlayImage:gradientImage overImage:imageWithBackground];
                } else {
                    UIImage *mainImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:event[@"cover"][@"source"]]]];
                    UIImage *gradientImage = [UIImage imageWithGradient:defaultCoverSize withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.6] withColor2:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2] vertical:NO];
                    event[@"cover"] = [UIImage overlayImage:gradientImage overImage:mainImage];
                }
                
            }
            
            
            completionBlock(hostEvents, guestEvents);
        }
    }];
}


@end
