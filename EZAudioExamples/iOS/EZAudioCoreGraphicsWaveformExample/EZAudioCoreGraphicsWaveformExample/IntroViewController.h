//
//  IntroViewController.h
//  noise
//
//  Created by Edward Sykes on 13/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IntroViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *connected;

- (IBAction)startClick:(id)sender;
@end
