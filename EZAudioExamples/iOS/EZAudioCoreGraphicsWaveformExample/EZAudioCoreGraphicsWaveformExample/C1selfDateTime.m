//
//  C1selfDateTime.m
//  noise
//
//  Created by Edward Sykes on 23/03/2015.
//  Copyright (c) 2015 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "C1selfDateTime.h"

NSString* getLocalDateTime(){
    NSDate* ts_utc = [NSDate date];
    
    NSDateFormatter* df_local = [[NSDateFormatter alloc] init];
    [df_local setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];
    
    NSString* result = [df_local stringFromDate:ts_utc];
    return result;
}