//
//  NoiseModel.h
//  noise
//
//  Created by Edward Sykes on 17/10/2014.


#ifndef noise_NoiseModel_h
#define noise_NoiseModel_h

#import "EZAudio.h"

@interface NoiseModel : NSObject<EZMicrophoneDelegate>

@property (nonatomic,strong) EZMicrophone *microphone;
@end
#endif
