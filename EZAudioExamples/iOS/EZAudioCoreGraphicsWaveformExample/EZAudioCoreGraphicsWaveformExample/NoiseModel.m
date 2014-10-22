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
@synthesize sampleSplMean;
@synthesize dbaMean;
@synthesize lat;
@synthesize lng;
@synthesize sumDbaCount;
@synthesize sumDba;
@synthesize log;

#pragma mark - Initialization
- (id) init{
    log = [NSMutableString new];
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

-(void) logMessage:(NSString*)message{
    [log appendString: message];
    [log appendString: @"\n"];
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
        [self logMessage: @"No stream id found, creating a new one"];
        NSDictionary* headers = @{@"Authorization": @"1selfnoise:12345678"};
        NSString* url = [NSString stringWithFormat: @"%@/v1/streams", apiUrlStem];
        
        UNIHTTPJsonResponse* response = [[UNIRest post:^(UNISimpleRequest* request) {
            [request setUrl: url];
            [request setHeaders:headers];
        }] asJson];
        
        if (response.code == 200) {
            [self logMessage:[NSString stringWithFormat:@"Successfully made rest call: %ld", (long)response.code] ];
            
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
            UIAlertView *theAlert = [[UIAlertView alloc] initWithTitle:@"1self cloud alert"
                                                               message:@"Hey! Just to let you know, we couldn't reach the 1self cloud. Panic not, we'll trap the samples until you're reconnected, then we'll re-send them. One minor thing, since the visualisations are powered by our cloud, you won't be able to see the visualization until the interwebs are back."
                                                              delegate:self
                                                     cancelButtonTitle:@"OK computer"
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
        
        sampleSplMean = [self dbaToDbspl:sampleDbaMean];
        
        //  NSLog(@"mean is %10f (raw) %10f (db)", rawMeanVal, dbMeanVal);
        sumDba += sampleDbaMean;
        sumDbaCount = sumDbaCount + 1;
        meanDba = sumDba / sumDbaCount;
        fdbspl = [self dbaToDbspl: meanDba];
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
    
    NSNumber *latitude = currentLocation == nil ? [NSNumber numberWithDouble:0]: [NSNumber numberWithDouble:currentLocation.coordinate.latitude];
    
    NSNumber *longitude = currentLocation == nil ?  [NSNumber numberWithDouble:0] : [NSNumber numberWithDouble:currentLocation.coordinate.longitude];
    NSDictionary *event = @{ @"dateTime":   formattedDateString,
                             @"eventDateTime": formattedDateString,
                             @"actionTags": @[@"sample"],
                             @"location": @{ @"lat": latitude,
                                             @"long": longitude
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
    if(sid == nil){
        return;
    }
    
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


-(float)dbaToDbspl:(float)dba{
    float result;
    if(dba > 0) {
        result = 150;
    }
    else if(dba > -1) {
        result = 147.5;
    }
    else if(dba > -2) {
        result = 145;
    }
    else if(dba > -3) {
        result = 142.5;
    }
    else if(dba > -4) {
        result = 140;
    }
    else if(dba > -5) {
        result = 137.5;
    }
    else if(dba > -6) {
        result = 135;
    }
    else if(dba > -7) {
        result = 132.5;
    }
    else if(dba > -8) {
        result = 130;
    }
    else if(dba > -9) {
        result = 127.5;
    }
    else if(dba > -10) {
        result = 125;
    }
    else if(dba > -11) {
        result = 122.5;
    }
    else if(dba > -12) {
        result = 120;
    }
    else if(dba > -13) {
        result = 117.5;
    }
    else if(dba > -14) {
        result = 115;
    }
    else if(dba > -15) {
        result = 112.5;
    }
    else if(dba > -16) {
        result = 110;
    }
    else if(dba > -17) {
        result = 107.5;
    }
    else if(dba > -18) {
        result = 105;
    }
    else if(dba > -19) {
        result = 102.5;
    }
    else if(dba > -20) {
        result = 100;
    }
    else if(dba > -21) {
        result = 98.92857143;
    }
    else if(dba > -22) {
        result = 97.85714286;
    }
    else if(dba > -23) {
        result = 96.78571429;
    }
    else if(dba > -24) {
        result = 95.71428571;
    }
    else if(dba > -25) {
        result = 94.64285714;
    }
    else if(dba > -26) {
        result = 93.57142857;
    }
    else if(dba > -27) {
        result = 92.5;
    }
    else if(dba > -28) {
        result = 91.42857143;
    }
    else if(dba > -29) {
        result = 90.35714286;
    }
    else if(dba > -30) {
        result = 89.28571429;
    }
    else if(dba > -31) {
        result = 88.21428571;
    }
    else if(dba > -32) {
        result = 87.14285714;
    }
    else if(dba > -33) {
        result = 86.07142857;
    }
    else if(dba > -34) {
        result = 85;
    }
    else if(dba > -35) {
        result = 83.92857143;
    }
    else if(dba > -36) {
        result = 82.85714286;
    }
    else if(dba > -37) {
        result = 81.78571429;
    }
    else if(dba > -38) {
        result = 80.71428571;
    }
    else if(dba > -39) {
        result = 79.64285714;
    }
    else if(dba > -40) {
        result = 78.57142857;
    }
    else if(dba > -41) {
        result = 77.5;
    }
    else if(dba > -42) {
        result = 76.42857143;
    }
    else if(dba > -43) {
        result = 75.35714286;
    }
    else if(dba > -44) {
        result = 74.28571429;
    }
    else if(dba > -45) {
        result = 73.21428571;
    }
    else if(dba > -46) {
        result = 72.14285714;
    }
    else if(dba > -47) {
        result = 71.07142857;
    }
    else if(dba > -48) {
        result = 70;
    }
    else if(dba > -49) {
        result = 68.57142857;
    }
    else if(dba > -50) {
        result = 67.14285714;
    }
    else if(dba > -51) {
        result = 65.71428571;
    }
    else if(dba > -52) {
        result = 64.28571429;
    }
    else if(dba > -53) {
        result = 62.85714286;
    }
    else if(dba > -54) {
        result = 61.42857143;
    }
    else if(dba > -55) {
        result = 60;
    }
    else if(dba > -56) {
        result = 59.84615385;
    }
    else if(dba > -57) {
        result = 59.69230769;
    }
    else if(dba > -58) {
        result = 59.53846154;
    }
    else if(dba > -59) {
        result = 59.38461538;
    }
    else if(dba > -60) {
        result = 59.23076923;
    }
    else if(dba > -61) {
        result = 59.07692308;
    }
    else if(dba > -62) {
        result = 58.92307692;
    }
    else if(dba > -63) {
        result = 58.76923077;
    }
    else if(dba > -64) {
        result = 58.61538462;
    }
    else if(dba > -65) {
        result = 58.46153846;
    }
    else if(dba > -66) {
        result = 58.30769231;
    }
    else if(dba > -67) {
        result = 58.15384615;
    }
    else if(dba > -68) {
        result = 58;
    }
    else if(dba > -69) {
        result = 57.84615385;
    }
    else if(dba > -70) {
        result = 57.69230769;
    }
    else if(dba > -71) {
        result = 57.53846154;
    }
    else if(dba > -72) {
        result = 57.38461538;
    }
    else if(dba > -73) {
        result = 57.23076923;
    }
    else if(dba > -74) {
        result = 57.07692308;
    }
    else if(dba > -75) {
        result = 56.92307692;
    }
    else if(dba > -76) {
        result = 56.76923077;
    }
    else if(dba > -77) {
        result = 56.61538462;
    }
    else if(dba > -78) {
        result = 56.46153846;
    }
    else if(dba > -79) {
        result = 56.30769231;
    }
    else if(dba > -80) {
        result = 56.15384615;
    }
    else if(dba > -81) {
        result = 56;
    }
    else if(dba > -82) {
        result = 55.84615385;
    }
    else if(dba > -83) {
        result = 55.69230769;
    }
    else if(dba > -84) {
        result = 55.53846154;
    }
    else if(dba > -85) {
        result = 55.38461538;
    }
    else if(dba > -86) {
        result = 55.23076923;
    }
    else if(dba > -87) {
        result = 55.07692308;
    }
    else if(dba > -88) {
        result = 54.92307692;
    }
    else if(dba > -89) {
        result = 54.76923077;
    }
    else if(dba > -90) {
        result = 54.61538462;
    }
    else if(dba > -91) {
        result = 54.46153846;
    }
    else if(dba > -92) {
        result = 54.30769231;
    }
    else if(dba > -93) {
        result = 54.15384615;
    }
    else if(dba > -94) {
        result = 54;
    }
    else if(dba > -95) {
        result = 53.84615385;
    }
    else if(dba > -96) {
        result = 53.69230769;
    }
    else if(dba > -97) {
        result = 53.53846154;
    }
    else if(dba > -98) {
        result = 53.38461538;
    }
    else if(dba > -99) {
        result = 53.23076923;
    }
    else if(dba > -100) {
        result = 53.07692308;
    }
    else if(dba > -101) {
        result = 52.92307692;
    }
    else if(dba > -102) {
        result = 52.76923077;
    }
    else if(dba > -103) {
        result = 52.61538462;
    }
    else if(dba > -104) {
        result = 52.46153846;
    }
    else if(dba > -105) {
        result = 52.30769231;
    }
    else if(dba > -106) {
        result = 52.15384615;
    }
    else if(dba > -107) {
        result = 52;
    }
    else if(dba > -108) {
        result = 51.84615385;
    }
    else if(dba > -109) {
        result = 51.69230769;
    }
    else if(dba > -110) {
        result = 51.53846154;
    }
    else if(dba > -111) {
        result = 51.38461538;
    }
    else if(dba > -112) {
        result = 51.23076923;
    }
    else if(dba > -113) {
        result = 51.07692308;
    }
    else if(dba > -114) {
        result = 50.92307692;
    }
    else if(dba > -115) {
        result = 50.76923077;
    }
    else if(dba > -116) {
        result = 50.61538462;
    }
    else if(dba > -117) {
        result = 50.46153846;
    }
    else if(dba > -118) {
        result = 50.30769231;
    }
    else if(dba > -119) {
        result = 50.15384615;
    }
    else if(dba > -120) {
        result = 50;
    }
    else if(dba > -121) {
        result = 48.82352941;
    }
    else if(dba > -122) {
        result = 47.64705882;
    }
    else if(dba > -123) {
        result = 46.47058824;
    }
    else if(dba > -124) {
        result = 45.29411765;
    }
    else if(dba > -125) {
        result = 44.11764706;
    }
    else if(dba > -126) {
        result = 42.94117647;
    }
    else if(dba > -127) {
        result = 41.76470588;
    }
    else if(dba > -128) {
        result = 40.58823529;
    }
    else if(dba > -129) {
        result = 39.41176471;
    }
    else if(dba > -130) {
        result = 38.23529412;
    }
    else if(dba > -131) {
        result = 37.05882353;
    }
    else if(dba > -132) {
        result = 35.88235294;
    }
    else if(dba > -133) {
        result = 34.70588235;
    }
    else if(dba > -134) {
        result = 33.52941176;
    }
    else if(dba > -135) {
        result = 32.35294118;
    }
    else if(dba > -136) {
        result = 31.17647059;
    }
    else if(dba > -137) {
        result = 30;
    }
    else if(dba > -138) {
        result = 28.69565217;
    }
    else if(dba > -139) {
        result = 27.39130435;
    }
    else if(dba > -140) {
        result = 26.08695652;
    }
    else if(dba > -141) {
        result = 24.7826087;
    }
    else if(dba > -142) {
        result = 23.47826087;
    }
    else if(dba > -143) {
        result = 22.17391304;
    }
    else if(dba > -144) {
        result = 20.86956522;
    }
    else if(dba > -145) {
        result = 19.56521739;
    }
    else if(dba > -146) {
        result = 18.26086957;
    }
    else if(dba > -147) {
        result = 16.95652174;
    }
    else if(dba > -148) {
        result = 15.65217391;
    }
    else if(dba > -149) {
        result = 14.34782609;
    }
    else if(dba > -150) {
        result = 13.04347826;
    }
    else if(dba > -151) {
        result = 11.73913043;
    }
    else if(dba > -152) {
        result = 10.43478261;
    }
    else if(dba > -153) {
        result = 9.130434783;
    }
    else if(dba > -154) {
        result = 7.826086957;
    }
    else if(dba > -155) {
        result = 6.52173913;
    }
    else if(dba > -156) {
        result = 5.217391304;
    }
    else if(dba > -157) {
        result = 3.913043478;
    }
    else if(dba > -158) {
        result = 2.608695652;
    }
    else if(dba > -159) {
        result = 1.304347826;
    }
    else if(dba > -160) {
        result = 0;
    }
    
    return result;
}
@end