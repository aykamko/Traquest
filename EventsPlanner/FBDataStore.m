//
//  FBDataStore.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/24/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import <FacebookSDK/FacebookSDK.h>
#import "FBDataStore.h"
@interface FBDataStore(){
    NSMutableArray *_array;
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

- (void)fetchEventListDataWithCompletion:(void (^)(NSArray *eventData))completionBlock
{

    _array = [NSMutableArray array];
   
    FBRequest *request = [FBRequest requestForGraphPath:@"me/events"];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (error) {
            NSLog(@"Error for events request!");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error!"
                                                            message:error.localizedDescription
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        } else {
            
            FBGraphObject *fbGraphObj=(FBGraphObject *)result;
            NSArray *graphArray=fbGraphObj[@"data"];
            NSMutableArray *eventsArray = [[NSMutableArray alloc] init];
            
            for (FBGraphObject *user in graphArray) {
                NSMutableDictionary *userDict = user;
                [eventsArray addObject:userDict];
            }
            
            NSLog(@"%@", eventsArray);
            completionBlock(eventsArray);
        }
    }];
}


@end
