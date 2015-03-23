//
//  NoiseModel.h
//  noise
//
//  Created by Edward Sykes on 17/10/2014.


#ifndef noise_NoiseModel_h
#define noise_NoiseModel_h

#import "EZAudio.h"
#import <CoreLocation/CoreLocation.h>
#import "EventRepository.h"

@protocol NoiseView <NSObject>
@optional
- (void)load;
- (void)updateView;
-(void)updateAudioPlots:(float *)buffer
     withBufferSize:(UInt32)bufferSize;
-(void)goToBackground;
-(void)goToForeground;

@end

@interface NoiseModel : NSObject<EZMicrophoneDelegate, CLLocationManagerDelegate>

@property (nonatomic,strong) EZMicrophone *microphone;
@property NSNumber* dbspl;
@property float mindbspl;
@property float maxdbspl;
@property float fdbspl;
@property NSTimeInterval sampleDuration;
@property NSString *autouploadLeft;
@property (weak) id<NoiseView> noiseView;
@property bool connected;
@property id<EventRepository> eventRepository; // eas: I've exposed this here, but if we need to send more events we should probably create an event model and move all the event sending stuff from here into that model.


@property float sampleRawMean;
@property float sampleDbaMean;
@property float sampleSplMean;
@property float dbaMean;
@property float lat;
@property float lng;
@property int sumDbaCount;
@property float sumDba;
@property NSMutableString* log;
@property bool noiseModel;

-(void) load;
-(void)persist;
-(void)persistImmediately;
-(void)openVisualization;

-(void) goToBackground;
-(void) didEnterBackground;
-(void) goToForeground;
-(void) becameActive;

-(void) logMessage:(NSString*)message;

-(int) samplesSent;
-(NSMutableArray*) samplesToSend;
-(int) samplesSending;
-(NSMutableArray*) fullHistory;

-(void) connect;
-(void) disconnect;

@end


#endif
