//
//  MKGeocodingsService.m
//  EventsPlanner
//
//  Created by Aleks Kamko on 7/29/13.
//  Copyright (c) 2013 FBU. All rights reserved.
//

#import "MKGeocodingService.h"
#import <CoreLocation/CoreLocation.h>

@interface MKGeocodingService () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    NSURLConnection *_geocodeConnection;
    NSMutableData *_container;
}
@property (nonatomic, copy) void (^completionBlock) (NSDictionary *geocode, NSError *error);
@property (nonatomic, strong) NSString *address;
@end

@implementation MKGeocodingService

- (void)fetchGeocodeAddress:(NSString *)address
                 completion:(void (^)(NSDictionary *geocode, NSError *error))completionBlock
{
    _address = address;
    _completionBlock = completionBlock;
    
    NSString *geocodingBaseURL = @"http://maps.googleapis.com/maps/api/geocode/json?";
    NSString *URL = [NSString stringWithFormat:@"%@address=%@&sensor=false",
                     geocodingBaseURL,
                     address];
    URL = [URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *queryURL = [NSURL URLWithString:URL];
    NSURLRequest *request = [NSURLRequest requestWithURL:queryURL];
    
    _container = [[NSMutableData alloc] init];
    _geocodeConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (NSDictionary *)makeDictionaryFromFetchedData:(NSData *)data
{
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data
                                                         options:kNilOptions
                                                           error:&error];
    
    NSArray *results = [json objectForKey:@"results"];
    NSDictionary *result = [results firstObject];
    NSString *address = [result objectForKey:@"formatted_address"];
    NSDictionary *geometry = [result objectForKey:@"geometry"];
    NSDictionary *locationDict = [geometry objectForKey:@"location"];
    NSString *latText = [locationDict objectForKey:@"lat"];
    NSString *lngText = [locationDict objectForKey:@"lng"];
    double latitude = [latText doubleValue];
    double longitude = [lngText doubleValue];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    
    if (!location)
        location = [[CLLocation alloc] initWithLatitude:0 longitude:0];
    
    if (!address)
        address = _address;
    
    return @{@"location":location, @"address":address};
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [_container appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSDictionary *geocode = [self makeDictionaryFromFetchedData:_container];
    if ([self completionBlock])
        [self completionBlock](geocode, nil);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if ([self completionBlock])
        [self completionBlock](nil, error);
}

@end
