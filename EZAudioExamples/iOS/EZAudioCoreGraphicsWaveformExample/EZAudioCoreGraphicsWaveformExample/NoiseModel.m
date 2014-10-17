//
//  NoiseModel.m
//  noise
//
//  Created by Edward Sykes on 17/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoiseModel.h"

@implementation NoiseModel

@synthesize microphone;

#pragma mark - Initialization
- (id) init{
    AudioStreamBasicDescription dataFormat;
    dataFormat.mSampleRate = 10;
    dataFormat.mFormatID = kAudioFormatLinearPCM;
    dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsBigEndian;
    dataFormat.mBytesPerPacket = 4;
    dataFormat.mFramesPerPacket = 1;
    dataFormat.mBytesPerFrame = 4;
    dataFormat.mChannelsPerFrame = 2;
    dataFormat.mBitsPerChannel = 8;
    
    self.microphone = [EZMicrophone microphoneWithDelegate:self withAudioStreamBasicDescription:dataFormat];
    [self.microphone startFetchingAudio];
    NSLog(@"Initted");
    return self;
}

// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
    
    // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.
    
    
    
    NSLog(@"Received");
}
-(void)microphone:(EZMicrophone *)microphone hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription {
    // The AudioStreamBasicDescription of the microphone stream. This is useful when configuring the EZRecorder or telling another component what audio format type to expect.
    // Here's a print function to allow you to inspect it a little easier
    [EZAudio printASBD:audioStreamBasicDescription];
}

-(void)microphone:(EZMicrophone *)microphone
    hasBufferList:(AudioBufferList *)bufferList
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
    // Getting audio data as a buffer list that can be directly fed into the EZRecorder or EZOutput. Say whattt...
}

@end