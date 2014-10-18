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


@end

@interface NoiseModel : NSObject<EZMicrophoneDelegate, CLLocationManagerDelegate>

@property (nonatomic,strong) EZMicrophone *microphone;
@property NSNumber* dbspl;
@property float fdbspl;
@property NSTimeInterval sampleDuration;
@property NSString *autouploadLeft;
@property (weak) id<NoiseView> noiseView;
@property int samplesSent;
@property int samplesSending;
@property int samplesSaved;

-(void) load;
-(void)persist;
-(void)sendSampleImmediately;
-(void)openVisualization;

@end


#endif
