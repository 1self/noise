//
//  EventRepository.m
//  noise
//
//  Created by Edward Sykes on 03/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "C1selfEventRepository.h"
#import <UNIRest.h>
#import "AppDelegate.h"
//#import <CoreLocation/CoreLocation.h>


@interface C1selfEventRepository (){
    NSMutableArray *unsentEvents;
    NSString* apiUrlStem;
    NSString *sid;
    NSString *writeToken;
    NSString *readToken;
    
}

@end

@implementation C1selfEventRepository
@synthesize samplesToSend;
@synthesize log;
@synthesize samplesSent;
@synthesize samplesSending;
@synthesize backgroundTask;
@synthesize fullHistory;

-(id) init{
    writeToken=@"";
    readToken=@"";
    backgroundTask = UIBackgroundTaskInvalid;
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    apiUrlStem = appDelegate.apiUrl;
    return self;
}

-(void) logMessage:(NSString*)message{
    [log appendString: message];
    [log appendString: @"\n"];
}

-(void) createStream{
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    sid = [loadPrefs stringForKey:@"streamid"];
    readToken = [loadPrefs stringForKey:@"readToken"];
    writeToken = [loadPrefs stringForKey:@"writeToken"];
    if(sid == nil){
        [self logMessage: @"No stream id found, creating a new one"];
        NSDictionary* headers = @{@"Authorization": @"1selfnoise:12345678"};
        NSString* url = [NSString stringWithFormat: @"%@/v1/streams", apiUrlStem];
        
        UNIHTTPJsonResponse* response = [[UNIRest post:^(UNISimpleRequest* request) {
            [request setUrl: url];
            [request setHeaders:headers];
        }] asJson];
        
        if (response.code == 200) {
            [self logMessage:[NSString stringWithFormat:@"Successfully made rest call: %ld", (long)response.code] ];
            
            sid = response.body.JSONObject[@"streamid"];
            writeToken = response.body.JSONObject[@"writeToken"];
            readToken = response.body.JSONObject[@"readToken"];
            
            NSLog(@"streamid: %@", sid);
            NSLog(@"writeToken: %@", writeToken);
            NSLog(@"readToken: %@", readToken);
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject: sid forKey:@"streamid"];
            [prefs setObject: writeToken forKey:@"writeToken"];
            [prefs setObject: readToken forKey:@"readToken"];
            
            
        }
        else{
            NSLog(@"Couldn't create stream, stream is blank, nothing will be persisted to QD");
        }
    }
}

- (void)loadHistory {
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    NSArray *fullHistoryFromStorage = [loadPrefs objectForKey:@"fullHistory"];
    fullHistory = [[NSMutableArray alloc] initWithCapacity:0];
    if(fullHistoryFromStorage != nil){
        for (int i = 0; i < fullHistoryFromStorage.count; ++i) {
            [fullHistory addObject:fullHistoryFromStorage[i]];
        }
    }
}

-(void) load{
    [self loadHistory];
    [self loadUnsentEvents];
    [self createStream];
}

-(void) loadUnsentEvents{
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
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    if(sid != nil){
        sid = [loadPrefs stringForKey:@"streamid"];
        readToken = [loadPrefs stringForKey:@"readToken"];
        writeToken = [loadPrefs stringForKey:@"writeToken"];
        [self SendUnsentSamples];
    }
}

- (void)addUnsentEvent:(NSDictionary *)event
{
    @synchronized(unsentEvents)
    {
        [unsentEvents addObject:event];
        samplesToSend = unsentEvents;
    }
}

- (void)SendEventAsync:(NSDictionary *)event
{
    // stream couldn't be created
    if(sid == nil){
        [self createStream];
        if(sid == nil)
        {
            [self addUnsentEvent:event];
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            @synchronized(unsentEvents){
                [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
            }
            return;
        }
    }
    
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"Authorization": writeToken};
    NSString *url = [NSString stringWithFormat:@"%@/v1/streams/%@/events", apiUrlStem, sid];
    NSData* json = [NSJSONSerialization dataWithJSONObject:event options:0 error:nil];
    NSString *jsonLog = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
    NSLog(@"sending json %@", jsonLog);
    samplesSending += 1;
    [[UNIRest postEntity:^(UNIBodyRequest* request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:event options:0 error:nil]];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // This is the asyncronous callback block
        NSInteger result = response.code;
        NSLog(@"Tried to send event with result %ld", (long)result);
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if(result == 200){
            samplesSent += 1;
        }
        else{
            [self addUnsentEvent:event];
        }
        
        @synchronized(unsentEvents){
            [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
            samplesToSend = unsentEvents;
        }
        
        // If we are being put in the background there might be a background task going.
        // So set this in case.
        if(backgroundTask != UIBackgroundTaskInvalid){
            backgroundTask = UIBackgroundTaskInvalid;
        }
        
        samplesSending -= 1;
    }];
}

- (void)SendEvent:(NSDictionary *)event
{
    if(sid == nil){
        [self addUnsentEvent:event];
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        @synchronized(unsentEvents){
            [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
        }
        return;
    }
    else{
        event = @{ @"dateTime":   event[@"dateTime"],
                   @"actionTags": event[@"actionTags"],
                  // @"location": event[@"location"],
                   @"objectTags":event[@"objectTags"],
                   @"properties": event[@"properties"],
                   @"source": event[ @"source"],
                   @"version": event[@"version"]
                   };
    }
    
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"Authorization": writeToken};
    NSString *url = [NSString stringWithFormat:@"%@/v1/streams/%@/events", apiUrlStem, sid];
    
    UNIHTTPJsonResponse* response = [[UNIRest postEntity:^(UNIBodyRequest* request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:event options:0 error:nil]];
    }] asJson];
    
    NSInteger result = response.code;
    NSLog(@"Tried to send event with result %ld", (long)result);
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if(result == 200){
        samplesSent += 1;
    }
    else{
        
        @synchronized(unsentEvents){
            [unsentEvents addObject:event];
            samplesToSend = unsentEvents;
        }
    }
    
    @synchronized(unsentEvents){
        [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
    }
    
    // If we are being put in the background there might be a background task going.
    // So set this in case.
    if(backgroundTask != UIBackgroundTaskInvalid){
        backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (NSDictionary *)CreateEvent:(NSDate *)currentTime sampleDuration:(NSTimeInterval)sampleDuration
                        dbspl: (NSNumber*) dbspl
                     mindbspl: (float) mindbspl
                     maxdbspl: (float) maxdbspl
                      meanDba: (float) meanDba
              //currentLocation: (CLLocation*) currentLocation
                  sampleStart: (NSDate*) sampleStart;
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    
    NSString *formattedDateString = [formatter stringFromDate:sampleStart];
    NSLog(@"ISO-8601 date: %@", formattedDateString);
    
    NSNumber* sampleDbspl = [NSNumber numberWithFloat: [dbspl intValue]];
    NSNumber* sampleMinDbspl = [NSNumber numberWithFloat: mindbspl ];
    NSNumber* sampleMaxDbspl = [NSNumber numberWithFloat: maxdbspl ];
    NSNumber* sampleDba = [NSNumber numberWithFloat: meanDba ];
    
//    NSNumber *latitude = currentLocation == nil ? [NSNumber numberWithDouble:0]: [NSNumber numberWithDouble:currentLocation.coordinate.latitude];
//    
//    NSNumber *longitude = currentLocation == nil ?  [NSNumber numberWithDouble:0] : [NSNumber numberWithDouble:currentLocation.coordinate.longitude];
    
    NSDictionary *event = @{ @"dateTime":   formattedDateString,
                             @"actionTags": @[@"sample"],
//                             @"location": @{ @"lat": latitude,
//                                             @"long": longitude
//                                             },
                             @"objectTags":@[@"ambient", @"sound"],
                             @"properties": @{@"dbspl": sampleDbspl,
                                              @"dba": sampleDba,
                                              @"mindbspl": sampleMinDbspl,
                                              @"maxdbspl": sampleMaxDbspl,
                                              @"durationMs": [NSNumber numberWithFloat: sampleDuration * 1000]},
                             @"source": @"1Self Noise",
                             @"version": @"1.0.0"
                             };
    
    [fullHistory addObject:event];
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setValue: fullHistory  forKey:@"fullHistory"];
    
    return event;
}

- (void)SendSamples:(NSDictionary*) event
{
    NSMutableArray *eventsToSend = [[NSMutableArray alloc] init];
    [eventsToSend addObject:event];
    
    for (int i = 0; i < unsentEvents.count; i++) {
        [eventsToSend addObject:unsentEvents[i]];
    }
    
    [unsentEvents removeAllObjects];
    samplesToSend = unsentEvents;
    
    for (int i = 0; i < eventsToSend.count; i++) {
        [self SendEventAsync:eventsToSend[i]];
    }
}

- (void)SendSamplesSync:(NSDictionary*) event
{
    NSMutableArray *eventsToSend = [[NSMutableArray alloc] init];
    [eventsToSend addObject:event];
    
    for (int i = 0; i < unsentEvents.count; i++) {
        [eventsToSend addObject:unsentEvents[i]];
    }
    
    [unsentEvents removeAllObjects];
    samplesToSend = unsentEvents;
    
    for (int i = 0; i < eventsToSend.count; i++) {
        [self SendEvent:eventsToSend[i]];
    }
}

- (void)SendSingleSample: (NSDictionary* )event
{
    if(sid == nil){
        return;
    }
    
    backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    [self SendEvent:event];
}

- (void)SendUnsentSamples
{
    NSMutableArray *eventsToSend = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < unsentEvents.count; i++) {
        [eventsToSend addObject:unsentEvents[i]];
    }
    
    [unsentEvents removeAllObjects];
    
    for (int i = 0; i < eventsToSend.count; i++) {
        [self SendEventAsync:eventsToSend[i]];
    }
}

-(NSString*)getVizUrl
{
    return [NSString stringWithFormat:@"%@/v1/streams/%@/events/ambient,sound/sample/mean(dbspl)/daily/barchart?readToken=%@", apiUrlStem, sid, readToken];
}

@end
