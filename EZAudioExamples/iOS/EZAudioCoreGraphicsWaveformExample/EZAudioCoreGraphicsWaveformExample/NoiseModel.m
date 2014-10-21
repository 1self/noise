//
//  NoiseModel.m
//  noise
//
//  Created by Edward Sykes on 17/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "NoiseModel.h"
#import <Accelerate/Accelerate.h>
#import <UNIRest.h>
#import <UIKit/UIKit.h>

@interface NoiseModel(){
    float meanDba;
    NSDate* sampleStart;
    int sampleSendFrequency;
    NSMutableArray *unsentEvents;
    NSString *sid;
    NSString *writeToken;
    NSString *readToken;
    NSString* apiUrlStem;
    CLLocation* currentLocation;
    UIBackgroundTaskIdentifier backgroundTask;
    CLLocationManager* locationManager;
}

#pragma mark - UI Extras
@end

@implementation NoiseModel
@synthesize microphone;
@synthesize dbspl;
@synthesize fdbspl;
@synthesize sampleDuration;
@synthesize autouploadLeft;
@synthesize samplesSent;
@synthesize samplesSending;
@synthesize samplesToSend;
@synthesize sampleRawMean;
@synthesize sampleDbaMean;
@synthesize dbaMean;
@synthesize lat;
@synthesize lng;
@synthesize sumDbaCount;
@synthesize sumDba;

#pragma mark - Initialization
- (id) init{
    dbspl = 0;
    meanDba = 0;
    sampleSendFrequency = 20;
    NSMutableArray *unsentEvents = nil;
    dbspl = [NSNumber numberWithInt:0];
    meanDba = 0;
    sid = @"";
    writeToken=@"";
    readToken=@"";
    // fake local api
    //apiUrlStem = @"http://10.0.1.15:7000";
    //appUrlStem = @"http://10.0.1.15:7000";
    
    // real local api
    // apiUrlStem = @"http://localhost:5000";
    // appUrlStem = @"http://localhost:5000";
    
    // LIVE!!
    //apiUrlStem = @"http://app.quantifieddev.org";
    
    // staging 1self
    //apiUrlStem = @"http://api-staging.1self.co:5000";
    
    // EE Office
    //apiUrlStem = @"http://10.5.5.44:7000";
    //appUrlStem = @"http://10.5.5.44:7000";
    
    //apiUrlStem = @"http://localhost:7000";
    //appUrlStem = @"http://localhost:7000";
    //apiUrlStem = @"http://api.1self.co";
    //appUrlStem = @"http://app.1self.co";
    apiUrlStem = @"http://api-staging.1self.co:5000";
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    
    if ([CLLocationManager locationServicesEnabled]) {
        [locationManager startUpdatingLocation];
    } else {
        NSLog(@"Location services is not enabled");
    }
    // Check for iOS 8. Without this guard the code will crash with "unknown selector" on iOS 7.
    if ([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [locationManager requestWhenInUseAuthorization];
    }
    
    currentLocation = [locationManager location];
    backgroundTask = UIBackgroundTaskInvalid;
    
    return self;
}

-(void) load{
    [self startMicrophone];
    [self logModelLoaded];
    [self loadUnsentEvents];
    [self createStream];
    [self sendSavedEvents];
    [_noiseView load];
}

-(void) startMicrophone{
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
}

- (void) logModelLoaded{
    NSLog(@"model loaded");
}

-(void) loadUnsentEvents{
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    
    //[loadPrefs removeObjectForKey:@"unsentEvents"];
    NSArray *savedUnsentEvents = [loadPrefs objectForKey:@"unsentEvents"];
    unsentEvents = [[NSMutableArray alloc] initWithCapacity:0];
    if(savedUnsentEvents != nil){
        for (int i = 0; i < savedUnsentEvents.count; ++i) {
            [unsentEvents addObject:savedUnsentEvents[i]];
        }
    }
}

-(void) createStream{
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    NSString *streamCreated = [loadPrefs stringForKey:@"streamid"];
    if(streamCreated == nil){
        NSLog(@"No stream id found, creating a new one");
        NSDictionary* headers = @{@"Authorization": @"1selfnoise:12345678"};
        NSString* url = [NSString stringWithFormat: @"%@/v1/streams", apiUrlStem];
        
        UNIHTTPJsonResponse* response = [[UNIRest post:^(UNISimpleRequest* request) {
            [request setUrl: url];
            [request setHeaders:headers];
        }] asJson];
        
        if (response.code == 200) {
            NSLog(@"Successfully made rest call: %ld", (long)response.code);
            
            sid = response.body.JSONObject[@"streamid"];
            writeToken = response.body.JSONObject[@"writeToken"];
            readToken = response.body.JSONObject[@"readToken"];
            
            NSLog(@"streamid: %@", sid);
            NSLog(@"writeToken: %@", writeToken);
            NSLog(@"readToken: %@", readToken);
            
            NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
            [prefs setObject: sid forKey:@"streamid"];
            [prefs setObject: writeToken forKey:@"writeToken"];
            [prefs setObject: readToken forKey:@"readToken"];
            
            
        }
        else{
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"Can't connect to 1self!"
                                                               message:@"Hey! We need the internet to collect the noise samples you create. Don't worry, we'll keep a hold of the samples until you're reconnected, then we'll re-send them. Until 1self has the samples, you won't be able to see any visualisations."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK"
                                                     otherButtonTitles:nil];
            [theAlert show];

            NSLog(@"Couldn't create stream, stream is blank, nothing will be persisted to QD");
        }
    }
}

-(void) sendSavedEvents{
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];
    if(sid != nil){
        sid = [loadPrefs stringForKey:@"streamid"];
        readToken = [loadPrefs stringForKey:@"readToken"];
        writeToken = [loadPrefs stringForKey:@"writeToken"];
        [self SendUnsentSamples];
    }
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
        float one = 1;
        float* avBuffer = (float*)malloc(sizeof(float)*bufferSize);
        vDSP_vsq(buffer[0], 1, avBuffer, 1, bufferSize);
        vDSP_meanv(avBuffer, 1, &sampleRawMean, bufferSize);
        free(avBuffer);
        
        if(sampleRawMean == 0){
            NSLog(@"Skipping infinite reading");
            return;
        }
        
        vDSP_vdbcon(&sampleRawMean, 1, &one, &sampleDbaMean, 1, 1, 1);
        
        if(sampleDbaMean < -10000000){
            assert("throwing data away");
            return;
        }
        
        //  NSLog(@"mean is %10f (raw) %10f (db)", rawMeanVal, dbMeanVal);
        sumDba += sampleDbaMean;
        sumDbaCount = sumDbaCount + 1;
        meanDba = sumDba / sumDbaCount;
        fdbspl = meanDba + 150;
        dbspl = [NSNumber numberWithInt:fdbspl];
        lat = currentLocation.coordinate.latitude;
        lng = currentLocation.coordinate.longitude;
        
        
        
        sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
        NSTimeInterval fullSample = 60*sampleSendFrequency;
        NSTimeInterval timeLeftRamainingInSample = fullSample - sampleDuration;
        
        int mins = (int)timeLeftRamainingInSample / 60;
        int seconds = (int)timeLeftRamainingInSample % 60;
        autouploadLeft = [NSString stringWithFormat: @"%0*d:%0*d", 2, mins, 2, seconds];
        
        if(sampleDuration > fullSample){
            [self SendSamples:currentTime sampleDuration:sampleDuration];
        }
    //    NSLog(@"count %d %f (raw: %f)", totalDbaSampleCount, totalDba / totalDbaSampleCount + 150, sampleMeanDba);
        
        if(_noiseView != nil){
            [_noiseView updateView];
        }
    });

    
    
    //NSLog(@"Received");
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

-(void)reset1Self:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs removeObjectForKey:@"streamid"];
    [prefs removeObjectForKey:@"writeToken"];
    [prefs removeObjectForKey:@"readToken"];
    [prefs removeObjectForKey:@"unsentEvents"];
}

- (void)SendEventAsync:(NSDictionary *)event
{
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"Authorization": writeToken};
    NSString *url = [NSString stringWithFormat:@"%@/v1/streams/%@/events", apiUrlStem, sid];
    
    samplesSending += 1;
    [[UNIRest postEntity:^(UNIBodyRequest* request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:event options:0 error:nil]];
    }] asJsonAsync:^(UNIHTTPJsonResponse* response, NSError *error) {
        // This is the asyncronous callback block
        NSInteger result = response.code;
        NSLog(@"Tried to send event with result %ld", (long)result);
        
        NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
        if(result == 200){
            samplesSent += 1;
        }
        else{
                        @synchronized(unsentEvents){
                [unsentEvents addObject:event];
            }
        }
        
        @synchronized(unsentEvents){
            [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
        }
        
        // If we are being put in the background there might be a background task going.
        // So set this in case.
        if(backgroundTask != UIBackgroundTaskInvalid){
            backgroundTask = UIBackgroundTaskInvalid;
        }
        
        samplesSending -= 1;
    }];
}

- (void)SendEvent:(NSDictionary *)event
{
    NSDictionary* headers = @{@"Content-Type": @"application/json",
                              @"Authorization": writeToken};
    NSString *url = [NSString stringWithFormat:@"%@/v1/streams/%@/events", apiUrlStem, sid];
    
    UNIHTTPJsonResponse* response = [[UNIRest postEntity:^(UNIBodyRequest* request) {
        [request setUrl:url];
        [request setHeaders:headers];
        [request setBody:[NSJSONSerialization dataWithJSONObject:event options:0 error:nil]];
    }] asJson];
    
    NSInteger result = response.code;
    NSLog(@"Tried to send event with result %ld", (long)result);
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if(result == 200){
        samplesSent += 1;
    }
    else{
        
        @synchronized(unsentEvents){
            [unsentEvents addObject:event];
        }
    }
    
    @synchronized(unsentEvents){
        [prefs setValue: unsentEvents  forKey:@"unsentEvents"];
    }
    
    // If we are being put in the background there might be a background task going.
    // So set this in case.
    if(backgroundTask != UIBackgroundTaskInvalid){
        backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (NSDictionary *)CreateEvent:(NSDate *)currentTime sampleDuration:(NSTimeInterval)sampleDuration
{
    NSDateFormatter* eventDateTime = [[NSDateFormatter alloc] init];
    eventDateTime.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    
    NSString *formattedDateString = [eventDateTime stringFromDate:sampleStart];
    NSLog(@"ISO-8601 date: %@", formattedDateString);
    
    sampleStart = currentTime;
    
    
    
    NSNumber* sampleDbspl = [NSNumber numberWithFloat: [dbspl intValue]];
    NSNumber* sampleDba = [NSNumber numberWithFloat: meanDba ];
    NSDictionary *event = @{ @"dateTime":   formattedDateString,
                             @"eventDateTime": formattedDateString,
                             @"actionTags": @[@"sample"],
                             @"location": @{ @"lat": [NSNumber numberWithDouble:currentLocation.coordinate.latitude],
                                             @"long": [NSNumber numberWithDouble:currentLocation.coordinate.longitude]
                                             },
                             @"objectTags":@[@"ambient", @"sound"],
                             @"properties": @{@"dba": sampleDba, @"dbspl": sampleDbspl, @"durationMs": [NSNumber numberWithFloat: sampleDuration * 1000]},
                             @"source": @"1Self Noise",
                             @"streamid":sid,
                             @"version": @"1.0.0"
                             };
    return event;
}

- (void)SendSamples:(NSDate *)currentTime sampleDuration:(NSTimeInterval)sampleDuration
{
    NSMutableArray *eventsToSend = [[NSMutableArray alloc] init];
    NSDictionary *event;
    event = [self CreateEvent:currentTime sampleDuration:sampleDuration];
    [eventsToSend addObject:event];
    
    for (int i = 0; i < unsentEvents.count; i++) {
        [eventsToSend addObject:unsentEvents[i]];
    }
    
    [unsentEvents removeAllObjects];
    
    for (int i = 0; i < eventsToSend.count; i++) {
        [self SendEventAsync:eventsToSend[i]];
    }
    
    [self resetSample];
}

- (void)SendSingleSample:(NSDate *)currentTime sampleDuration:(NSTimeInterval)sampleDuration
{
    NSMutableArray *eventsToSend = [[NSMutableArray alloc] init];
    NSDictionary *event;
    event = [self CreateEvent:currentTime sampleDuration:sampleDuration];
    [self SendEvent:event];
    [self resetSample];
}

- (void)SendUnsentSamples
{
    NSMutableArray *eventsToSend = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < unsentEvents.count; i++) {
        [eventsToSend addObject:unsentEvents[i]];
    }
    
    [unsentEvents removeAllObjects];
    
    for (int i = 0; i < eventsToSend.count; i++) {
        [self SendEventAsync:eventsToSend[i]];
    }
}

- (void) persist
{
    NSDate* currentTime = [NSDate date];
    NSTimeInterval sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
    [self SendSamples: currentTime sampleDuration: sampleDuration];
    [self resetSample];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocations:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self->currentLocation = newLocation;
    
    NSLog(@"Latidude %f Longitude: %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [locationManager stopUpdatingLocation];
    NSLog(@"Update failed with error: %@", error);
}

-(void) resetSample{
    sumDbaCount = 0;
    sumDba = 0;
    sampleStart = [NSDate date];
    dbspl = 0;
    meanDba = 0;
}

-(void) didEnterBackground{
    NSLog(@"NoiseModel didEnterBackground");
}

-(void) goToForeground{
    NSLog(@"Model goToForeground");
    [self startMicrophone];
    [_noiseView goToForeground];
}
-(void) becameActive{
    NSLog(@"Model didEnterBackground");
}

-(void) goToBackground {
    NSLog(@"NoiseModel goToBackground");
    [self.microphone stopFetchingAudio];
    NSDate* currentTime = [NSDate date];
    sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
    [self SendSingleSample:currentTime sampleDuration: sampleDuration];
    
    
    backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    [self resetSample];
}

- (void) sendSampleImmediately{
    [self.microphone stopFetchingAudio];
    NSDate* currentTime = [NSDate date];
    NSTimeInterval sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
    [self SendSingleSample:currentTime sampleDuration: sampleDuration];
    
    backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    [self resetSample];
}

-(void)openVisualization{
    NSString *vizUrl = [NSString stringWithFormat:@"%@/v1/streams/%@/events/ambient,sound/sample/mean(dbspl)/daily/barchart", apiUrlStem, sid];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:vizUrl]];
}



@end