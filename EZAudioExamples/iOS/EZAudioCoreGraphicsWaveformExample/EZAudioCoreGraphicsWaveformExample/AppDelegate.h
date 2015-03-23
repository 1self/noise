//
//  AppDelegate.h
//  Noise
//
//  Created by Syed Haris Ali on 12/15/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NoiseModel.h"
#import "BeaconModel.h"
#import "HelpModel.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property NoiseModel* noiseModel;
@property BeaconModel* beaconModel;
@property HelpModel* helpModel;
@property NSString* apiUrl;

- (void)createModels;
- (void)testMode;
- (void)testHttpMode;
- (void)stagingMode;
- (void)stagingHttpMode;
- (void)liveMode;
- (void)liveHttpMode;

@end
