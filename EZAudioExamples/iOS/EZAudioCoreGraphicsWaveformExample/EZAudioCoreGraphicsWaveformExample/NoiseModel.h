//
//  NoiseModel.h
//  noise
//
//  Created by Edward Sykes on 17/10/2014.


#ifndef noise_NoiseModel_h
#define noise_NoiseModel_h

#import "EZAudio.h"
#import <CoreLocation/CoreLocation.h>

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
@property bool connected;

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
-(int) samplesToSend;
-(int) samplesSending;

@end


#endif
