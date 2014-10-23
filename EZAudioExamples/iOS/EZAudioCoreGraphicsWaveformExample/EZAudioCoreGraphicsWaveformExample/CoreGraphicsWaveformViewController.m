    //
//  CoreGraphicsWaveformViewController.m
//  EZAudioCoreGraphicsWaveformExample
//
//  Created by Syed Haris Ali on 12/15/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//

#import "NoiseModel.h"

#import "CoreGraphicsWaveformViewController.h"
#import <Accelerate/Accelerate.h>
#import "AppDelegate.h"
#import <sys/utsname.h>

@interface CoreGraphicsWaveformViewController (){
  float scale;
}
#pragma mark - UI Extras
@property (nonatomic,weak) IBOutlet UILabel *microphoneTextLabel;
@property (nonatomic,weak) IBOutlet UILabel *lblDba;
@property (weak, nonatomic) IBOutlet UILabel *lblMinDbspl;
@property (weak, nonatomic) IBOutlet UILabel *lblMaxDbSpl;
@property (nonatomic,weak) IBOutlet UILabel *lblDbspl;
@property (nonatomic,weak) IBOutlet UILabel *sampleSent;
@property (weak, nonatomic) IBOutlet UILabel *samplesToSend;
@property (weak, nonatomic) IBOutlet UILabel *samplesSending;
@property (nonatomic,weak) IBOutlet UILabel *lbl;
@property (nonatomic, weak) IBOutlet UIImageView *innerTicker;
@property (nonatomic, weak) IBOutlet UIImageView *middleTicker;
@property (nonatomic, weak) IBOutlet UIImageView *outerTicker;
@property (weak, nonatomic) IBOutlet UILabel *iphone4SamplesToSend;
@property (weak, nonatomic) IBOutlet UILabel *iphoneSamplesSending;
@property (weak, nonatomic) IBOutlet UILabel *iphone4SamplesSent;
@property (weak, nonatomic) IBOutlet UIView *iphone4feedback;
@property (weak, nonatomic) IBOutlet UIView *feedback;
@property (weak, nonatomic) IBOutlet UILabel *dbraw;
@end

@implementation CoreGraphicsWaveformViewController
@synthesize audioPlot;

NSNumber *dbspl = 0;
NSNumber *dba = 0;

NoiseModel* noiseModel;

#pragma mark - Initialization
-(id)init {
  self = [super init];
  if(self){
    [self initializeViewController];
  }
    
    return self;
}

- (void) initializeViewController{
    
}

- (bool) isIphone4{
    bool result = false;
    if([[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone)
    {
        if ([[UIScreen mainScreen] bounds].size.height < 568)
        {
            
            result = true;
        }
        
    }
    return result;
}

-(id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if(self){
    [self initializeViewController];
  }
  return self;
}

#pragma mark - Initialize View Controller Here

-(void)updateAudioPlots:(float *)buffer withBufferSize:(UInt32)bufferSize{
    [self.audioPlot updateBuffer:buffer withBufferSize:bufferSize];
}

- (void)updateView{
    if([self isIphone4]){
        _iphone4feedback.hidden = false;
        _feedback.hidden = true;
    }
    dbspl = noiseModel.dbspl;
    [self UpdateUIStats];
    [self UpdateViewBackground];
    
}

- (void) animateWaveform
{
    
    [self.audioPlot setAlpha:0];
    [UIView beginAnimations:NULL context:nil];
    [UIView setAnimationDuration:2.0];
    [self.audioPlot setAlpha:0];
    [UIView setAnimationDuration:2.0];
    [self.audioPlot setAlpha:0.8];
    [UIView commitAnimations];
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
- (void)setInitialPlotColour
{
    self.audioPlot.backgroundColor = [UIColor colorWithRed:0.9 green:0.471 blue:0.525 alpha:0];
    self.audioPlot.color           = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
    self.audioPlot.plotType        = EZPlotTypeBuffer;
}

-(void)goToBackground{
    
}
-(void)goToForeground{
}

- (void)animate
{
    [self animateInner];
    [self animateMiddle];
    [self animateOuter];
    [self animateWaveform];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    noiseModel = appDelegate.noiseModel;
    noiseModel.noiseView = self;
    [self setInitialPlotColour];
    [self animate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self setInitialPlotColour];
    [self animate];
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


- (IBAction)vizTapHandler:(id)sender {
    [noiseModel persist];
    [self.meterView2 setAlpha:0];
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
    [self animateInner];
    [self animateOuter];
    [self animateMiddle];
}

- (void) applicationActive{
    [self resetSample];
}

- (void)UpdateUIStats
{
    self.lblDbspl.text = [NSString stringWithFormat: @"%@", noiseModel.dbspl];
    self.lblMinDbspl.text = [NSString stringWithFormat: @"%0.f", noiseModel.mindbspl];
    self.lblMaxDbSpl.text = [NSString stringWithFormat: @"%0.f", noiseModel.maxdbspl];
    self.sampleSent.text = [NSString stringWithFormat: @"%d", noiseModel.samplesSent];
    self.samplesToSend.text = [NSString stringWithFormat: @"%d", noiseModel.samplesToSend];
    self.samplesSending.text = [NSString stringWithFormat: @"%d", noiseModel.samplesSending];
    self.autoupload.text = [NSString stringWithFormat: @"Auto-upload in\n%@", noiseModel.autouploadLeft];
    self.dbraw.text = [NSString stringWithFormat:@"%.12f", noiseModel.sampleRawMean];
}

- (void)UpdateViewBackground
{
    float redness = noiseModel.fdbspl / 100;
    float greenness = 1 - redness;
    self.view.backgroundColor = [UIColor colorWithRed:redness green:greenness blue:0.4 alpha:1];
    audioPlot.backgroundColor = [UIColor colorWithRed:redness green:greenness blue:0.4 alpha:1];
}


- (IBAction)graphTap:(id)sender {
    [noiseModel sendSampleImmediately];
    [noiseModel openVisualization];
}


- (IBAction)help:(id)sender {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"HelpView"];
        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        [self presentViewController:vc animated:YES completion:nil];
}

- (IBAction)debug:(id)sender {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"DebugView"];
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:vc animated:YES completion:nil];
}
@end
