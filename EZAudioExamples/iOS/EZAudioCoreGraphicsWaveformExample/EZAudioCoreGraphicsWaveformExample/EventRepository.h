//
//  EventRepository.h
//  noise
//
//  Created by Edward Sykes on 04/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#ifndef noise_EventRepository_h
#define noise_EventRepository_h

#import <CoreLocation/CoreLocation.h>

@protocol EventRepository <NSObject>

-(void) SendSamples: (NSDictionary*) event;
-(void) SendSamplesSync: (NSDictionary*) event;
-(void) SendSingleSample: (NSDictionary*) event;
-(void) SendSingleSampleAsync: (NSDictionary* )event;
-(NSString*) getVizUrl;
-(NSDictionary*) CreateEvent: (NSDate*) currentTime
              sampleDuration: (NSTimeInterval) sampleDuration
                       dbspl: (NSNumber*) dbspl
                    mindbspl: (float) mindbspl
                    maxdbspl: (float) maxdbspl
                     meanDba: (float) meanDba
            // currentLocation: (CLLocation*) currentLocation
                 sampleStart: (NSDate*) sampleStart;
-(void) load;
-(void) sendSavedEvents;
-(void) createStream;

@property NSMutableArray* fullHistory;
@property NSMutableArray* samplesToSend;
@property int samplesSent;
@property int samplesSending;

@end

#endif
