//
//  BeaconProximityEventFactory.h
//  noise
//
//  Created by Edward Sykes on 23/03/15.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#ifndef noise_BeaconProximityEventFactory_h
#define noise_BeaconProximityEventFactory_h

@interface BeaconEventFactory : NSObject  

- (NSDictionary *)CreateOnEvent:(NSString*)uuid major:(NSNumber*)major minor:(NSNumber*)minor;
- (NSDictionary *)CreateOffEvent:(NSString*)uuid major:(NSNumber*)major minor:(NSNumber*)minor;


@end

#endif
