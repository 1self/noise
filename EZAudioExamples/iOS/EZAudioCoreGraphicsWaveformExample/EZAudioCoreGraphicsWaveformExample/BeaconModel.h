//
//  BeaconModel.h
//  noise
//
//  Created by Edward Sykes on 23/03/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#ifndef noise_BeaconModel_h
#define noise_BeaconModel_h

@import CoreLocation;
@import CoreBluetooth;
#import "NoiseModel.h"

@interface BeaconModel : NSObject<CLLocationManagerDelegate, CBPeripheralManagerDelegate>

@property bool enabled;

-(void) load:(NoiseModel*)noiseModel;
-(void) goToForeground;
-(void) goToBackground;
-(void) startAdvertisingBeacon;
-(void) stopAdvertisingBeacon;

@end
#endif
