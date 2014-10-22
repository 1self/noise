//
//  DebugController.m
//  noise
//
//  Created by Edward Sykes on 21/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import "NoiseModel.h"
#import "DebugController.h"
#import "AppDelegate.h"

@interface DebugController ()
@property NoiseModel* noiseModel;
@property (weak, nonatomic) IBOutlet UILabel *sampleRawMean;
@property (weak, nonatomic) IBOutlet UILabel *sampleDbaMean;
@property (weak, nonatomic) IBOutlet UILabel *sampleSplMean;
@property (weak, nonatomic) IBOutlet UILabel *sumDba;
@property (weak, nonatomic) IBOutlet UILabel *sumDbaCount;
@property (weak, nonatomic) IBOutlet UILabel *tosend;
@property (weak, nonatomic) IBOutlet UILabel *sending;
@property (weak, nonatomic) IBOutlet UILabel *sent;
@property (weak, nonatomic) IBOutlet UILabel *autoupload;
@property (weak, nonatomic) IBOutlet UILabel *location;
@property (weak, nonatomic) IBOutlet UITextView *log;
@end

@implementation DebugController

- (void)viewDidLoad {
    [super viewDidLoad];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    _noiseModel = appDelegate.noiseModel;
    _noiseModel.noiseView = self;
    _log.text = _noiseModel.log;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateView{
    _sampleRawMean.text = [NSString stringWithFormat: @"sampleRawMean: %.12f", _noiseModel.sampleRawMean];
    _sampleDbaMean.text = [NSString stringWithFormat: @"sampleDbaMean: %.12f", _noiseModel.sampleDbaMean];
    _sampleSplMean.text = [NSString stringWithFormat: @"sampleSplMean: %.12f", _noiseModel.sampleSplMean];
    _sumDba.text = [NSString stringWithFormat: @"sumDba:%.12f", _noiseModel.sumDba];
    _sumDbaCount.text = [NSString stringWithFormat: @"sumDbaCount%d",_noiseModel.sumDbaCount];
    _tosend.text = [NSString stringWithFormat: @"toSend%d", _noiseModel.samplesToSend];
    _sending.text = [NSString stringWithFormat: @"sending%d", _noiseModel.samplesSending];
    _sent.text = [NSString stringWithFormat: @"sent%d", _noiseModel.samplesSent];
    _autoupload.text = _noiseModel.autouploadLeft;
    _location.text = [NSString stringWithFormat: @"lat:%f,long%f", _noiseModel.lat, _noiseModel.lng];
    
    
}

-(void)updateAudioPlots:(float *)buffer withBufferSize:(UInt32)bufferSize{
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)tapBack:(id)sender {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainView"];
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:vc animated:YES completion:nil];
    [_noiseModel logMessage:@"Going into debug view"];
}
@end
