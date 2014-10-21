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

-(id)init{
    helpText = @"How loud is your life? Quiet as a mouse? Louder than an elephants trumpet? 1self Noise gives you the sound smarts to tell. Like a karma chameleon, the app changes colour. A tranquil green for when you're somewhere peaceful, an angry red when the world around you is GRRRRR! Nerrrd alert: dbspl is the boffin's way of measuring noise. Don't worry if you don't know what that is, there's a list below of decibel values for a few things you should be familiar with.\n\nIt's very well known that Elephants have tremendous memories. That's why we tied a few to balloons to hang around in the clouds to help us remember your Noise samples. Open up our visualization and the elephants will remember all your data and draw you a nice visualization. Which day of the week is quietest? Which the loudest? Are there any patterns? Don't disappoint Nellie after she worked so hard, show your data to your friends!\n\nAny would-be spies need to know that Noise isn't for secret agent snooping. We don't know what you're saying or what you're listening to, we just record how noisy it is.\n\n How noisy is your nine-to-five? How cacophonous is your commute? How buzzy is that bar? Noise will tell you!\n\nDisclaimer: Any elephants working in the cloud for us are looked after very well. There is a plentiful supply of peanuts, a huge waterpark and a strict mouse quarantine. We are also an equal opportunities employer of elephants, we do not discriminate on ear size";
    return self;
}

@end