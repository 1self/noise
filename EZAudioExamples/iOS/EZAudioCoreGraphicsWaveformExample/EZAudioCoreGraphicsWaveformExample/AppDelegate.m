//
//  AppDelegate.m
//  Noise
//
//  Created by Syed Haris Ali on 12/15/13.
//  Copyright (c) 2013 Syed Haris Ali. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize noiseModel;
@synthesize beaconModel;
@synthesize apiUrl;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [self liveMode];
    
    UIApplication *myApp = [UIApplication sharedApplication];
    myApp.idleTimerDisabled = YES;
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    bool introDone = [prefs objectForKey:@"introDone"];
    if(introDone){
        [self createModels];
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainView"];
        self.window.rootViewController = vc;
    }
    else{
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"Intro"];
        self.window.rootViewController = vc;
    }

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    if(noiseModel != nil)
    {
        [noiseModel goToBackground];
    }
    
    if(beaconModel != nil)
    {
        [beaconModel goToBackground];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    if(noiseModel != nil)
    {
        [noiseModel goToForeground];
    }
    
    if(beaconModel != nil)
    {
        [beaconModel goToForeground];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)createModels
{
    if(noiseModel == nil){
        noiseModel = [NoiseModel new];
        [noiseModel load];
    }
    
    if(beaconModel == nil){
        beaconModel = [BeaconModel new];
        [beaconModel load:noiseModel];
    }
}

- (void)testMode
{
    apiUrl = @"https://api-test.1self.co";
}

- (void)testHttpMode
{
    apiUrl = @"http://api-test.1self.co";
}

- (void)stagingMode
{
    apiUrl = @"https://api-staging.1self.co";
}

- (void)stagingHttpMode
{
    apiUrl = @"http://api-staging.1self.co";
}

- (void)liveMode
{
    apiUrl = @"https://api.1self.co";
}

- (void)liveHttpMode
{
    apiUrl = @"http://api.1self.co";
}

@end
