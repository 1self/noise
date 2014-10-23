//
//  HelpModel.m
//  noise
//
//  Created by Edward Sykes on 20/10/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HelpModel.h"
#import <UNIRest.h>

@implementation HelpModel

@synthesize helpText;

-(id)init{
    NSString* apiUrlStem = @"http://api.1self.co:5000";
    NSString* defaultText = @"Need help? We got you, keep scrolling for the details...\n\nHow loud is your life? Noise by 1self gives you the sound smarts to tell. Like us humans, the app changes colour depending on what’s happening: from quiet green to angry red. At a glance you can tell how GRRR the world around you is. \n\nThere’s a big clear readout of loudness in dbspl. Don't worry if you don't know what that is, there's a list below of decibel values for a few things you should be familiar with. There’s a min and a max because the world around us never sits still.\n\nYou data is sent to the 1self cloud automatically, building up the noisescape to your life. We don’t record any audio, just the noisyness. If you don’t want to wait for auto-upload, click on the dial or close the app. Both will fire off the sample currently being collected.\n\nAnd now, for the non-boffins, some things and how loud they are, so you can compare yourworld to some well known ear-splitters.\n\nJet aircraft, 50 m away: 140\nThreshold of pain: 130\nThreshold of discomfort: 120\nChainsaw, 1m distance: 110\nDisco, 1m from speaker: 100\nDiesel truck, 10m away: 90\nKerbside of busy road, 5m: 80\nVacuum cleaner, distance 1m : 70\nConversational speech, 1m: 60\nAverage home: 50\nQuiet library: 40\nQuiet bedroom at night: 30\nBackground in TV studio: 20\nRustling leaves in the distance: 10\nHearing threshold	: 0\n";
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    NSString *savedText = [prefs stringForKey:@"helptext"];
    if(savedText == nil){
        [prefs setObject: defaultText forKey:@"helptext"];
        savedText = [prefs stringForKey:@"helptext"];
    }
    
    helpText = savedText;
    
    NSString* url = [NSString stringWithFormat: @"%@/helptext/noise.txt", apiUrlStem];
    
    UNIHTTPStringResponse* response = [[UNIRest post:^(UNISimpleRequest* request) {
        [request setUrl: url];
    }] asString];
    
    if (response.code == 200) {
        NSString* newHelpText = response.body;
        [prefs setObject: newHelpText forKey:@"helptext"];
        savedText = [prefs stringForKey:@"helptext"];
        helpText = savedText;
    }
    
    return self;
}

@end