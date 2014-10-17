//
//  NoiseModel.m
//  noise
//
//  Created by Edward Sykes on 17/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NoiseView.h"
#import "NoiseModel.h"
#import <Accelerate/Accelerate.h>

@interface NoiseModel(){
    __block int totalDbaSampleCount;
    __block float totalDba;
    NSNumber *dba;
    NSDate* sampleStart;
    int sampleSendFrequency;
}

#pragma mark - UI Extras
@end

@implementation NoiseModel
@synthesize microphone;
@synthesize dbspl;
@synthesize fdbspl;
@synthesize sampleDuration;
@synthesize autouploadLeft;

#pragma mark - Initialization
- (id) init{
    dbspl = 0;
    dba = 0;
    sampleSendFrequency = 20;
    
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
    dispatch_async(dispatch_get_main_queue(),^{
        // Need to call the view model delegate here to update the UI.
        if(_noiseView != nil){
            [_noiseView updateAudioPlots:buffer[0] withBufferSize:bufferSize];
        }

             
        
        // Setup the sample start time
        if(sampleStart == nil){
            sampleStart = [NSDate date];
        }
        
        NSDate* currentTime = [NSDate date];
        
        //NSLog(@"buffer received %d %f", totalCount, totalLoudness);
        float rawMeanVal = 0.0;
        float one = 1;
        float* avBuffer = (float*)malloc(sizeof(float)*bufferSize);
        vDSP_vsq(buffer[0], 1, avBuffer, 1, bufferSize);
        vDSP_meanv(avBuffer, 1, &rawMeanVal, bufferSize);
        free(avBuffer);
        
        if(rawMeanVal == 0){
            NSLog(@"Skipping infinite reading");
            return;
        }
        
        float sampleMeanDba = 0;
        vDSP_vdbcon(&rawMeanVal, 1, &one, &sampleMeanDba, 1, 1, 1);
        
        if(sampleMeanDba < -10000000){
            //    NSLog(@"Skipping bad db value");
            return;
        }
        
        //  NSLog(@"mean is %10f (raw) %10f (db)", rawMeanVal, dbMeanVal);
        totalDba += sampleMeanDba;
        totalDbaSampleCount = totalDbaSampleCount + 1;
        dba = [NSNumber numberWithInt:totalDba / totalDbaSampleCount];
        fdbspl = totalDba / totalDbaSampleCount + 150;
        dbspl = [NSNumber numberWithInt:fdbspl];
        
        
        //Call the UI callback to update stats
        // needs to update text labels and update the colour of the ui, and the autouploads text
        
        sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
        NSTimeInterval fullSample = 60*sampleSendFrequency;
        NSTimeInterval timeLeftRamainingInSample = fullSample - sampleDuration;
        
        int mins = (int)timeLeftRamainingInSample / 60;
        int seconds = (int)timeLeftRamainingInSample % 60;
        autouploadLeft = [NSString stringWithFormat: @"Auto-upload in\n%0*d:%0*d", 2, mins, 2, seconds];
        
        //if(sampleDuration > fullSample){
        //    [self SendSamples:currentTime sampleDuration:sampleDuration];
        //}
        NSLog(@"count %d %f (raw: %f)", totalDbaSampleCount, totalDba / totalDbaSampleCount + 150, sampleMeanDba);
        
        if(_noiseView != nil){
            [_noiseView updateView];
        }
    });

    
    
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