//
//  LocalEventRepository.h
//  noise
//
//  Created by Edward Sykes on 04/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#ifndef noise_LocalEventRepository_h
#define noise_LocalEventRepository_h

#import <CoreLocation/CoreLocation.h>
#import "EventRepository.h"


@interface LocalEventRepository : NSObject<EventRepository>

@property NSMutableArray* samplesToSend;
@property NSMutableArray* fullHistory;
@property NSMutableString* log;
@property int samplesSent;
@property int samplesSending;
@property UIBackgroundTaskIdentifier backgroundTask;

-(void) sendSavedEvents;
-(void) addUnsentEvent: (NSDictionary*) event;
-(NSDictionary*) CreateEvent: (NSDate*) currentTime
              sampleDuration: (NSTimeInterval) sampleDuration
                       dbspl: (NSNumber*) dbspl
                    mindbspl: (float) mindbspl
                    maxdbspl: (float) maxdbspl
                     meanDba: (float) meanDba
             currentLocation: (CLLocation*) currentLocation
                 sampleStart: (NSDate*) sampleStart;
-(void) SendSamples: (NSDictionary*) event;
-(void) SendSingleSample: (NSDictionary*) event;
-(void) logMessage:(NSString*)message;
-(void) load;
-(NSString*) getVizUrl;
-(void) createStream;

@end

#endif
