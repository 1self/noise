//
//  HistoryViewController.h
//  noise
//
//  Created by Edward Sykes on 05/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HistoryViewController : UIViewController<NoiseView>


@property (weak, nonatomic) IBOutlet EZAudioPlotGL *audioPlot;
@property (weak, nonatomic) IBOutlet UILabel *lblDbspl;
@property (weak, nonatomic) IBOutlet UILabel *autoupload;
@property (weak, nonatomic) IBOutlet UITableView *historyTable;
- (IBAction)TapperDial:(id)sender;
@end
