//
//  Event Repository.h
//  noise
//
//  Created by Edward Sykes on 03/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#ifndef noise_Event_Repository_h
#define noise_Event_Repository_h

#import "EventRepository.h"
#import <CoreLocation/CoreLocation.h>


@interface C1selfEventRepository : NSObject<EventRepository>

@property NSMutableArray* samplesToSend;
@property NSMutableString* log;
@property int samplesSent;
@property int samplesSending;
@property UIBackgroundTaskIdentifier backgroundTask;

-(void) loadUnsentEvents;
-(void) sendSavedEvents;
-(void) addUnsentEvent: (NSDictionary*) event;
-(void) SendEventAsync;
-(void) SendEvent: (NSDictionary*) event;
-(NSDictionary*) CreateEvent: (NSDate*) currentTime
              sampleDuration: (NSTimeInterval) sampleDuration
                       dbspl: (NSNumber*) dbspl
                    mindbspl: (float) mindbspl
                    maxdbspl: (float) maxdbspl
                     meanDba: (float) meanDba
             currentLocation: (CLLocation*) currentLocation
                 sampleStart: (NSDate*) sampleStart;
-(void) SendSamples: (NSDictionary*) event;
-(void) SendSamplesSync: (NSDictionary*) event;
-(void) SendSingleSample: (NSDictionary*) event;
-(void) SendUnsentSamples;
-(void) persist;
-(void) logMessage:(NSString*)message;
-(void) load;
-(NSString*) getVizUrl;
-(void) createStream;




@end

#endif

