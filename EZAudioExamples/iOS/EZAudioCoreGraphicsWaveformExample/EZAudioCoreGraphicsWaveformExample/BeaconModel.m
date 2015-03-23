    //
//  BeaconModel.m
//  noise
//
//  Created by Edward Sykes on 23/03/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BeaconModel.h"
#import "BeaconEventFactory.h"
#import "NoiseModel.h"
#import "EventRepository.h"

static NSString * const beaconRegionId = @"co.1self.noise";

@interface BeaconModel(){
    CLBeaconRegion *beaconRegion;
    CBPeripheralManager *peripheralManager;
    NSString *regionId;
    BeaconEventFactory *beaconEventFactory;
    NoiseModel* noiseModel;
}
@end

@implementation BeaconModel

@synthesize enabled;

-(id) init {
    regionId = @"";
    enabled = false;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    regionId = [prefs objectForKey:@"regionId"];
    if(regionId == nil){
        CFUUIDRef udid = CFUUIDCreate(NULL);
        regionId = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, udid));
        [prefs setObject: regionId forKey:@"regionId"];
    }

    beaconEventFactory = [BeaconEventFactory new];
    
    enabled = [prefs boolForKey:@"beaconEnabled"];
    if(enabled){
        [self startAdvertisingBeacon];
    }
    

    return self;
}

-(void) load:(NoiseModel*)paramNoiseModel{
    noiseModel = paramNoiseModel;
}

-(void) goToForeground{
    NSLog(@"beaconModel goToForeground");
}

-(void) goToBackground {
    NSLog(@"beaconModel goToBackground");
}

- (void)createBeaconRegion
{
    if (beaconRegion)
        return;
    
    NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:regionId];
    beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:beaconRegionId];
    beaconRegion.notifyEntryStateOnDisplay = YES;
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheralManagerPassed
{
    if (peripheralManagerPassed.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        return;
    }
    
    if(enabled == false){
        NSLog(@"Beacon is disabled");
        return;
    }
    
    NSLog(@"Peripheral manager is on.");
    [self turnOnAdvertising];
}

- (void)turnOnAdvertising
{
    if (peripheralManager.state != CBPeripheralManagerStatePoweredOn) {
        NSLog(@"Peripheral manager is off.");
        return;
    }
    
    
    time_t t;
    srand((unsigned) time(&t));
    CLBeaconRegion *region = [[CLBeaconRegion alloc] initWithProximityUUID:beaconRegion.proximityUUID
                                                                     major:1
                                                                     minor:1
                                                                identifier:beaconRegion.identifier];
    NSDictionary *beaconPeripheralData = [region peripheralDataWithMeasuredPower:nil];
    [peripheralManager startAdvertising:beaconPeripheralData];
    
    NSLog(@"Turning on advertising for region: %@.", region);
}

- (void) startAdvertisingBeacon {
    NSLog(@"Turning on advertising...");
    enabled = true;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:true forKey: @"beaconEnabled"];
    
    [self createBeaconRegion];
    
    if (!peripheralManager)
        peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil options:nil];
    
    [self turnOnAdvertising];
    
    NSNumber *major = [NSNumber numberWithInt:1];
    NSNumber *minor = [NSNumber numberWithInt:1];
    
    NSDictionary* beaconOnEvent = [beaconEventFactory CreateOnEvent:regionId major:major minor:minor];
    [noiseModel.eventRepository SendSamples:beaconOnEvent];
    
};

- (void) stopAdvertisingBeacon {
    NSLog(@"stopping beacon");
    enabled = false;
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:false forKey: @"beaconEnabled"];
    
   [peripheralManager stopAdvertising];
    
    NSNumber *major = [NSNumber numberWithInt:1];
    NSNumber *minor = [NSNumber numberWithInt:1];
    
    NSDictionary* beaconOffEvent = [beaconEventFactory CreateOffEvent:regionId major:major minor:minor];
    [noiseModel.eventRepository SendSamples:beaconOffEvent];

}

@end

