    //
//  CoreGraphicsWaveformViewController.m
//  EZAudioCoreGraphicsWaveformExample
//
//  Created by Syed Haris Ali on 12/15/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//

#import "CoreGraphicsWaveformViewController.h"
#import <Accelerate/Accelerate.h>
#import <UNIRest.h>

@interface CoreGraphicsWaveformViewController (){
  float scale;
}
#pragma mark - UI Extras
@property (nonatomic,weak) IBOutlet UILabel *microphoneTextLabel;
@property (nonatomic,weak) IBOutlet UILabel *lblDba;
@property (nonatomic,weak) IBOutlet UILabel *lblDbspl;
@property (nonatomic,weak) IBOutlet UILabel *lblsamplesSent;
@property (weak, nonatomic) IBOutlet UILabel *lblsamplesSaved;
@property (weak, nonatomic) IBOutlet UILabel *lblSendingSamples;
@property (nonatomic,weak) IBOutlet UILabel *lbl;
@property (nonatomic, weak) IBOutlet UIImageView *innerTicker;
@property (nonatomic, weak) IBOutlet UIImageView *middleTicker;
@property (nonatomic, weak) IBOutlet UIImageView *outerTicker;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@end

@implementation CoreGraphicsWaveformViewController
@synthesize audioPlot;
@synthesize microphone;

NSNumber *dbspl = 0;
NSNumber *dba = 0;
NSMutableArray *unsentEvents = nil;

#pragma mark - Initialization
-(id)init {
  self = [super init];
  if(self){
    [self initializeViewController];
  }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self){
    [self initializeViewController];
  }
  return self;
}

#pragma mark - Initialize View Controller Here
- (void)CreateStream {
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
        NSLog(@"Couldn't create stream, stream is blank, nothing will be persisted to QD");
    }
}

-(void)initializeViewController {
    [self reset1Self: nil];
    [self registerGoingIntoBackgroundHandler];
    self.backgroundTask = UIBackgroundTaskInvalid;
  // Create an instance of the microphone and tell it to use this view controller instance as the delegate
    
    AudioStreamBasicDescription dataFormat;
    dataFormat.mSampleRate = 10;
    dataFormat.mFormatID = kAudioFormatLinearPCM;
    dataFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsBigEndian;
    dataFormat.mBytesPerPacket = 4;
    dataFormat.mFramesPerPacket = 1;
    dataFormat.mBytesPerFrame = 4;
    dataFormat.mChannelsPerFrame = 2;
    dataFormat.mBitsPerChannel = 8;
    
    sampleSendFrequency = 20;
    //self.microphone = [EZMicrophone microphoneWithDelegate:self withAudioStreamBasicDescription:dataFormat];
    totalDbaSampleCount = 0;
    totalDba = 0;
    samplesSent = 0;
    sendingSamples = 0;
    // fake local api
    //apiUrlStem = @"http://10.0.1.15:7000";
    //appUrlStem = @"http://10.0.1.15:7000";
    
    // real local api
    // apiUrlStem = @"http://localhost:5000";
    // appUrlStem = @"http://localhost:5000";
    
    // LIVE!!
    //apiUrlStem = @"http://app.quantifieddev.org";
    
    // staging 1self
    apiUrlStem = @"http://api-staging.1self.co:5000";
    
    // EE Office
    //apiUrlStem = @"http://10.5.5.44:7000";
    //appUrlStem = @"http://10.5.5.44:7000";
    
    //apiUrlStem = @"http://localhost:7000";
    //appUrlStem = @"http://localhost:7000";
    //apiUrlStem = @"http://api.1self.co";
    //appUrlStem = @"http://app.1self.co";
    dbspl = [NSNumber numberWithInt:0];
    dba = [NSNumber numberWithInt:0];
    sid = @"";
    writeToken=@"";
    readToken=@"";
    
    NSUserDefaults *loadPrefs = [NSUserDefaults standardUserDefaults];

    //[loadPrefs removeObjectForKey:@"unsentEvents"];
    NSArray *savedUnsentEvents = [loadPrefs objectForKey:@"unsentEvents"];
    unsentEvents = [[NSMutableArray alloc] initWithCapacity:0];
    if(savedUnsentEvents != nil){
        for (int i = 0; i < savedUnsentEvents.count; ++i) {
            [unsentEvents addObject:savedUnsentEvents[i]];
        }
    }
    
    [self UpdateUIStats];
    
    
    NSString *textToLoad = [loadPrefs stringForKey:@"streamid"];
    if(textToLoad == nil){
        [self CreateStream];
    }
    else{
        sid = [loadPrefs stringForKey:@"streamid"];
        readToken = [loadPrefs stringForKey:@"readToken"];
        writeToken = [loadPrefs stringForKey:@"writeToken"];
        [self SendUnsentSamples];
    }
    
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
    
    NSLog(@"stream id loaded: %@", textToLoad);
    
    UIApplication *myApp = [UIApplication sharedApplication];
    myApp.idleTimerDisabled = YES;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocations:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	self->currentLocation = newLocation;
	
	NSLog(@"Latidude %f Longitude: %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	[locationManager stopUpdatingLocation];
	NSLog(@"Update failed with error: %@", error);
}

- (void) animateInner
{
    float rotations = 1.0;
    int duration = 1;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1.0 * 60 * 60;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];

    
    [_innerTicker.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void) animateMiddle
{
    float rotations = 1.0 / 60;
    int duration = 1;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1.0 * 60 * 60;
    
    
    [_middleTicker.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (void) animateOuter
{
    float rotations = 1.0 / 60 / 20;
    int duration = 1;
    CABasicAnimation* rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * rotations * duration ];
    rotationAnimation.duration = duration;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = 1.0 * 60 * 60;
    
    
    [_outerTicker.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

#pragma mark - Customize the Audio Plot
- (void)viewDidLoad
{
  [super viewDidLoad];
  
  /*
   Customizing the audio plot's look
   */
  // Background colo
  self.audioPlot.backgroundColor = [UIColor colorWithRed:0.9 green:0.471 blue:0.525 alpha:0];
  // Waveform color
  self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
  // Plot type
  self.audioPlot.plotType        = EZPlotTypeBuffer;
  
  /*
   Start the microphone
   */
  [self.microphone startFetchingAudio];
  self.microphoneTextLabel.text = @"Microphone On";
    
    [self animateInner];
    [self animateMiddle];
    [self animateOuter];
    
}

#pragma mark - Actions
-(void)changePlotType:(id)sender {
  NSInteger selectedSegment = [sender selectedSegmentIndex];
  switch(selectedSegment){
    case 0:
      [self drawBufferPlot];
      break;
    default:
      break;
  }
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
    
    sendingSamples += 1;
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
        if(self.backgroundTask != UIBackgroundTaskInvalid){
            self.backgroundTask = UIBackgroundTaskInvalid;
        }
        
        sendingSamples -= 1;
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
        if(self.backgroundTask != UIBackgroundTaskInvalid){
            self.backgroundTask = UIBackgroundTaskInvalid;
        }
}

- (NSDictionary *)CreateEvent:(NSDate *)currentTime sampleDuration:(NSTimeInterval)sampleDuration
{
    NSDateFormatter* eventDateTime = [[NSDateFormatter alloc] init];
    eventDateTime.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    
    NSString *formattedDateString = [eventDateTime stringFromDate:sampleStart];
    NSLog(@"ISO-8601 date: %@", formattedDateString);
    
    sampleStart = currentTime;
    
    
    
    NSNumber* sampleDbspl = [NSNumber numberWithInt: [dbspl intValue]];
    NSNumber* sampleDba = [NSNumber numberWithInt: [dba intValue]];
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

- (IBAction)vizTapHandler:(id)sender {
    [self.meterView2 setAlpha:0];
    NSDate* currentTime = [NSDate date];
    NSTimeInterval sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
    [self SendSamples: currentTime sampleDuration: sampleDuration];
    [self resetSample];
    [UIView beginAnimations:NULL context:nil];
    [UIView setAnimationDuration:2.0];
    [self.meterView2 setAlpha:1];
    [UIView commitAnimations];
}

#pragma mark - Action Extensions
/*
 Give the visualization of the current buffer (this is almost exactly the openFrameworks audio input eample)
 */
-(void)drawBufferPlot {
  // Change the plot type to the buffer plot
  self.audioPlot.plotType = EZPlotTypeBuffer;
  // Don't mirror over the x-axis
  self.audioPlot.shouldMirror = YES;
  // Don't fill
  self.audioPlot.shouldFill = YES;
}

int samplePruining = 0;

#pragma mark - EZMicrophoneDelegate
#warning Thread Safety
- (void)resetSample
{
    totalDbaSampleCount = 0;
    totalDba = 0;
    sampleStart = [NSDate date];
    dbspl = 0;
    dba = 0;
    [self animateInner];
    [self animateOuter];
    [self animateMiddle];
}

- (void) applicationWillResign {
    [self.microphone stopFetchingAudio];
    NSDate* currentTime = [NSDate date];
    NSTimeInterval sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
    [self SendSingleSample:currentTime sampleDuration: sampleDuration];

    
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        self.backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    [self resetSample];
}

- (void) applicationActive{
    [self resetSample];
    [self.microphone startFetchingAudio];
}

- (void) registerGoingIntoBackgroundHandler {
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationWillResign)
     name:UIApplicationWillResignActiveNotification
     object:NULL];
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(applicationActive)
     name:UIApplicationDidBecomeActiveNotification
     object:NULL];
}

- (void)UpdateUIStats
{
    self.lblDba.text = [NSString stringWithFormat: @"%@ dba", dba];
    self.lblDbspl.text = [NSString stringWithFormat: @"%@", dbspl];
    self.lblsamplesSent.text = [NSString stringWithFormat: @"%d", samplesSent];
    self.lblsamplesSaved.text = [NSString stringWithFormat: @"%lu", (unsigned long)unsentEvents.count];
    self.lblSendingSamples.text = [NSString stringWithFormat: @"%d", sendingSamples];
}

// Note that any callback that provides streamed audio data (like streaming microphone input) happens on a separate audio thread that should not be blocked. When we feed audio data into any of the UI components we need to explicity create a GCD block on the main thread to properly get the UI to work.
-(void)microphone:(EZMicrophone *)microphone
 hasAudioReceived:(float **)buffer
   withBufferSize:(UInt32)bufferSize
withNumberOfChannels:(UInt32)numberOfChannels {
  // Getting audio data as an array of float buffer arrays. What does that mean? Because the audio is coming in as a stereo signal the data is split into a left and right channel. So buffer[0] corresponds to the float* data for the left channel while buffer[1] corresponds to the float* data for the right channel.
  
  // See the Thread Safety warning above, but in a nutshell these callbacks happen on a separate audio thread. We wrap any UI updating in a GCD block on the main thread to avoid blocking that audio flow.

    
    
    dispatch_async(dispatch_get_main_queue(),^{
        // All the audio plot needs is the buffer data (float*) and the size. Internally the audio plot will handle all the drawing related code, history management, and freeing its own resources. Hence, one badass line of code gets you a pretty plot :)
        [self.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
        samplePruining += 1;
        
       /* if(samplePruining % 10 != 0){
            return;
        }*/
            
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
        float fdbspl = totalDba / totalDbaSampleCount + 150;
        dbspl = [NSNumber numberWithInt:fdbspl];
        
        
        [self UpdateUIStats];
        
        float redness = fdbspl / 100;
        float greenness = 1 - redness;
        self.view.backgroundColor = [UIColor colorWithRed:redness green:greenness blue:0 alpha:1];
        audioPlot.backgroundColor = [UIColor colorWithRed:redness green:greenness blue:0 alpha:1];
        
        NSTimeInterval sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
        NSTimeInterval fullSample = 60*sampleSendFrequency;
        NSTimeInterval timeLeftRamainingInSample = fullSample - sampleDuration;
        
        int mins = (int)timeLeftRamainingInSample / 60;
        int seconds = (int)timeLeftRamainingInSample % 60;
        self.autoupload.text = [NSString stringWithFormat: @"Auto-upload in\n%0*d:%0*d", 2, mins, 2, seconds];
        
        if(sampleDuration > fullSample){
            [self SendSamples:currentTime sampleDuration:sampleDuration];
        }
        NSLog(@"count %d %f (raw: %f)", totalDbaSampleCount, totalDba / totalDbaSampleCount + 150, sampleMeanDba);
    
      
  });
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

- (IBAction)graphTap:(id)sender {
    [self.microphone stopFetchingAudio];
    NSDate* currentTime = [NSDate date];
    NSTimeInterval sampleDuration = [currentTime timeIntervalSinceDate:sampleStart];
    [self SendSingleSample:currentTime sampleDuration: sampleDuration];
    
    
    self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        self.backgroundTask = UIBackgroundTaskInvalid;
    }];
    
    [self resetSample];
    NSString* registerUrl = [NSString stringWithFormat: @"%@/v1/streams/%@/events/ambient;sound/sample/dbspl/mean/daily/barchart?readtoken=%@", apiUrlStem, sid, readToken];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:registerUrl]];
}
@end
