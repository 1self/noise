//
//  AppDelegate.h
//  Noise
//
//  Created by Syed Haris Ali on 12/15/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoiseModel.h"
#import "HelpModel.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property NoiseModel* noiseModel;
@property HelpModel* helpModel;

- (void)createModels;

@end
