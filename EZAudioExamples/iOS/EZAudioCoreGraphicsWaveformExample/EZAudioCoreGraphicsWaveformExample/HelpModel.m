//
//  HelpModel.m
//  noise
//
//  Created by Edward Sykes on 20/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelpModel.h"

@implementation HelpModel

@synthesize helpText;

-(id) Init{
    helpText = @"How loud is your life? 1self Noise makes you sound smart. The app shows green when you're somewhere peaceful. When your world turns angry, Noise hears and turns red. For the audio nerds there is even a decibel reading. Don't worry if you don't know what that is, there's a list below of decibel values for a few things you should be familiar with.\n\nNoise remembers all the different noise readings you take and shows you your noise history in beautiful visualizations. \n\nNoise doesn't record anything other than loudness. We don't know what you're saying or what you're listening to. So go ahead and find out how noisy your nine-to-five is, how buzzy a bar is or how the hush at home hits.";
    return self;
}

@end