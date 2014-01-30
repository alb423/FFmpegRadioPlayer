//
//  AppDelegate.m
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 13/4/19.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import "AppDelegate.h"
#import <AVFoundation/AVFoundation.h>



@implementation AppDelegate

extern NSString *remoteControlPlayButtonTapped;
extern NSString *remoteControlPauseButtonTapped;
extern NSString *remoteControlStopButtonTapped;
extern NSString *remoteControlForwardButtonTapped;
extern NSString *remoteControlBackwardButtonTapped;
extern NSString *remoteControlOtherButtonTapped;
extern NSString *remoteControlShowMessage;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    // For audio remote control
    // Reference: https://github.com/MosheBerman/ios-audio-remote-control
    
    NSError *setCategoryErr = nil;
    NSError *activationErr  = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setCategoryErr];
    
    if(![[AVAudioSession sharedInstance] setActive:YES error:&activationErr])
    {
        NSLog(@"Failed to set up a session.");
    }
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    
    [[AVAudioSession sharedInstance] setDelegate: self];
//    Delegate Methods
//    – beginInterruption
//    – endInterruption
//    – endInterruptionWithFlags:
//    – inputIsAvailableChanged:

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    NSLog(@"applicationWillResignActive");
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    [self postNotificationWithName:remoteControlShowMessage];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    NSLog(@"applicationWillTerminate");
    [application endReceivingRemoteControlEvents];
}


#pragma mark - control when screen is locked
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [self postNotificationWithName:remoteControlPlayButtonTapped];
            break;
        case UIEventSubtypeRemoteControlPause:
            [self postNotificationWithName:remoteControlPauseButtonTapped];
            break;
        case UIEventSubtypeRemoteControlStop:
            [self postNotificationWithName:remoteControlStopButtonTapped];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [self postNotificationWithName:remoteControlForwardButtonTapped];
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self postNotificationWithName:remoteControlBackwardButtonTapped];
            break;
        default:
            [self postNotificationWithName:remoteControlOtherButtonTapped];
            break;
    }
}

- (void)postNotificationWithName:(NSString *)name
{
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
}



#pragma mark - AVAudioSession delegate
- (void)beginInterruption{
    //播放器会话被终端拨，例如打电话
    NSLog(@"beginInterruption");
    [[NSNotificationCenter defaultCenter] postNotificationName:remoteControlStopButtonTapped object:nil];
}
- (void)endInterruption{
    NSLog(@"endInterruption");
}
- (void)endInterruptionWithFlags:(NSUInteger)flags{
    //被中断后回来，例如：挂断电话回来 endInterruptionWithFlags 1
    NSLog(@"endInterruptionWithFlags %i", flags);
    [[NSNotificationCenter defaultCenter] postNotificationName:remoteControlPlayButtonTapped object:nil];
}

#if 0
#pragma mark - ad_banner_view
- (BOOL) allowActionToRun
{
    return YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"didFailToReceiveAdWithError");
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    NSLog(@"Banner view is beginning an ad action");
    BOOL shouldExecuteAction = [self allowActionToRun]; // your application implements this method
    if (!willLeave && shouldExecuteAction)
    {
        // insert code here to suspend any services that might conflict with the advertisement
    }
    return shouldExecuteAction;
}
#endif



@end
