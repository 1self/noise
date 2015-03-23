//
//  HelpViewController.h
//  noise
//
//  Created by Edward Sykes on 21/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController<NoiseView>


@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (weak, nonatomic) IBOutlet UILabel *lblDbspl;
@property (weak, nonatomic) IBOutlet UILabel *autoupload;
@property (weak, nonatomic) IBOutlet UITextView *helpText;
- (IBAction)tapDial:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *connected;
- (IBAction)clickConnected:(id)sender;
- (IBAction)clickPublic:(UISwitch*)sender;
@property (weak, nonatomic) IBOutlet UISwitch *beaconEnabled;
@end
