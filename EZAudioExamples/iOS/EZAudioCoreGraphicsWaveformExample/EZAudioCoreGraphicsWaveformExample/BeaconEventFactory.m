//
//  BeaconEventFactory.m
//  noise
//
//  Created by Edward Sykes on 23/03/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeaconEventFactory.h"
#import "C1selfDateTime.h"

@interface BeaconEventFactory(){
    
}

@end

@implementation BeaconEventFactory

- (id) init {
    return self;
}

- (NSDictionary *)CreateOnEvent:(NSString*)uuid major:(NSNumber*)major minor:(NSNumber*)minor
{
    NSString* localDateTime = getLocalDateTime();
    NSDictionary *event = @{ @"dateTime": localDateTime,
                             @"actionTags": @[@"start"],
                             @"objectTags":@[@"proximity", @"beacon", @"ibeacon"],
                             @"properties": @{@"regionId": uuid,
                                              @"major": major,
                                              @"minor": minor
                             }
                            };
    return event;
}

- (NSDictionary *)CreateOffEvent:(NSString*)uuid major:(NSNumber*)major minor:(NSNumber*)minor
{
    NSString* localDateTime = getLocalDateTime();
    
    NSDictionary *event = @{ @"dateTime": localDateTime,
                             @"actionTags": @[@"stop"],
                             @"objectTags":@[@"proximity", @"beacon", @"ibeacon"],
                             @"properties": @{@"regionId": uuid,
                                              @"major": major,
                                              @"minor": minor
                                              }
                             };
    return event;
}

@end