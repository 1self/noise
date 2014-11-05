//
//  LocalEventRepository.m
//  noise
//
//  Created by Edward Sykes on 04/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalEventRepository.h"
#import <UNIRest.h>
#import <CoreLocation/CoreLocation.h>


@interface LocalEventRepository (){
    NSMutableArray *unsentEvents;
    NSString* apiUrlStem;
}

@end

@implementation LocalEventRepository
@synthesize samplesToSend;
@synthesize log;
@synthesize samplesSent;
@synthesize samplesSending;
@synthesize backgroundTask;

-(id) init{
    apiUrlStem = @"https://api-test.1self.co";
    return self;
}

-(void) logMessage:(NSString*)message{
    [log appendString: message];
    [log appendString: @"\n"];
}

-(void) load{
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    
    //[loadPrefs removeObjectForKey:@"unsentEvents"];
    NSArray *savedUnsentEvents = [loadPrefs objectForKey:@"unsentEvents"];
    unsentEvents = [[NSMutableArray alloc] initWithCapacity:0];
    if(savedUnsentEvents != nil){
        for (int i = 0; i < savedUnsentEvents.count; ++i) {
            [unsentEvents addObject:savedUnsentEvents[i]];
        }
    }
    
    samplesToSend = unsentEvents;

}

-(void) sendSavedEvents{
    // nothing to do, we don't send events to the server when working in local mode
}

- (void)addUnsentEvent:(NSDictionary *)event{
    [unsentEvents addObject:event];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
}

- (NSDictionary *)CreateEvent:(NSDate *)currentTime sampleDuration:(NSTimeInterval)sampleDuration
                        dbspl: (NSNumber*) dbspl
                     mindbspl: (float) mindbspl
                     maxdbspl: (float) maxdbspl
                      meanDba: (float) meanDba
              currentLocation: (CLLocation*) currentLocation
                  sampleStart: (NSDate*) sampleStart;
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:SS'Z'";
    
    NSString *formattedDateString = [formatter stringFromDate:sampleStart];
    NSLog(@"ISO-8601 date: %@", formattedDateString);
    
    NSNumber* sampleDbspl = [NSNumber numberWithFloat: [dbspl intValue]];
    NSNumber* sampleMinDbspl = [NSNumber numberWithFloat: mindbspl ];
    NSNumber* sampleMaxDbspl = [NSNumber numberWithFloat: maxdbspl ];
    NSNumber* sampleDba = [NSNumber numberWithFloat: meanDba ];
    
    NSNumber *latitude = currentLocation == nil ? [NSNumber numberWithDouble:0]: [NSNumber numberWithDouble:currentLocation.coordinate.latitude];
    
    NSNumber *longitude = currentLocation == nil ?  [NSNumber numberWithDouble:0] : [NSNumber numberWithDouble:currentLocation.coordinate.longitude];
    
    
    NSString* streamid =  @"";
    
    NSDictionary *event = @{ @"dateTime":   formattedDateString,
                             @"actionTags": @[@"sample"],
                             @"location": @{ @"lat": latitude,
                                             @"long": longitude
                                             },
                             @"objectTags":@[@"ambient", @"sound"],
                             @"properties": @{@"dba": sampleDba,
                                              @"dbspl": sampleDbspl,
                                              @"mindbspl": sampleMinDbspl,
                                              @"maxdbspl": sampleMaxDbspl,
                                              @"durationMs": [NSNumber numberWithFloat: sampleDuration * 1000]},
                             @"source": @"1Self Noise",
                             @"version": @"1.0.0"
                             };
    return event;
}

- (void)SendSamples:(NSDictionary*) event
{
    [self addUnsentEvent:event];
}

- (void)SendSingleSample:(NSDictionary* )event
{
    [self addUnsentEvent:event];
}

-(NSString*)getVizUrl
{
    return @"";
}

@end
