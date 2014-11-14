//
//  IntroViewController.m
//  noise
//
//  Created by Edward Sykes on 13/11/2014.
//  Copyright (c) 2014 Syed Haris Ali. All rights reserved.
//

#import "IntroViewController.h"
#import "AppDelegate.h"

@interface IntroViewController ()

@end

@implementation IntroViewController
@synthesize connected;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void) viewDidAppear:(BOOL)animated
{
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    bool introDone = [prefs objectForKey:@"introDone"];
    if(introDone){
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate createModels];
        appDelegate.noiseModel.connected = connected.selected;

        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainView"];
        
        [self presentViewController:vc animated:NO completion:nil];
    }
}

- (IBAction)startClick:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    [prefs setBool:true forKey: @"introDone"];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate createModels];
    
    if(connected.on)
    {
        [appDelegate.noiseModel connect];
    }
    

    
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
    UIViewController *vc = [mainStoryboard instantiateViewControllerWithIdentifier:@"MainView"];
    vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:vc animated:YES completion:nil];
    
    
}
@end
