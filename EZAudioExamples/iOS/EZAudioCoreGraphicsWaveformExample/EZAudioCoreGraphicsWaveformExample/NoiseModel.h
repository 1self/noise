//
//  NoiseModel.h
//  noise
//
//  Created by Edward Sykes on 17/10/2014.


#ifndef noise_NoiseModel_h
#define noise_NoiseModel_h

#import "EZAudio.h"

@protocol NoiseView <NSObject>
@optional
- (void)updateView;
-(void)updateAudioPlots:(float *)buffer
     withBufferSize:(UInt32)bufferSize;

@end

@interface NoiseModel : NSObject<EZMicrophoneDelegate>

@property (nonatomic,strong) EZMicrophone *microphone;
@property NSNumber* dbspl;
@property float fdbspl;
@property NSTimeInterval sampleDuration;
@property NSString *autouploadLeft;
@property (weak) id<NoiseView> noiseView;

@end


#endif
