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
                if(!event[@"cover"]) {
                    event[@"cover"] = [UIImage imageWithGradient:CGSizeMake(1000, 1000) withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] withColor2:[UIColor colorWithRed:1 green:1 blue:1 alpha:0] vertical:NO];
                } else {
                    event[@"cover"] = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:event[@"cover"][@"source"]]]];
                    
                    UIImage *backgroundImage = event[@"cover"];
                    UIImage *watermarkImage = [UIImage imageWithGradient:backgroundImage.size withColor1:[UIColor colorWithRed:0 green:0 blue:0 alpha:1] withColor2:[UIColor colorWithRed:1 green:1 blue:1 alpha:0] vertical:NO];
                    
                    UIGraphicsBeginImageContext(backgroundImage.size);
                    [backgroundImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];
                    [watermarkImage drawInRect:CGRectMake(0, 0, backgroundImage.size.width, backgroundImage.size.height)];
                    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    event[@"cover"] = result;
                }
                
            }
            

        completionBlock(hostEvents, guestEvents);
        }
    }];
}


@end
