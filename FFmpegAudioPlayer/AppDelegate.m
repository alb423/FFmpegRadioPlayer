//
//  AppDelegate.m
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 13/4/19.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import "AppDelegate.h"
#import "MediaPlayer/MPNowPlayingInfoCenter.h"
#import "MediaPlayer/MPMediaItem.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
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
    
    [application beginReceivingRemoteControlEvents];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    [application endReceivingRemoteControlEvents];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - control when screen is locked

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    
    if(event.type== UIEventTypeRemoteControl)  {
        
        NSLog(@"Remote Control Type: %d", event.subtype);
        
        switch (event.subtype) {
                
            case UIEventSubtypeRemoteControlTogglePlayPause:
                
                NSLog(@"UIEventSubtypeRemoteControlTogglePlayPause");
                
                break;
                
                
            case UIEventSubtypeRemoteControlNextTrack:
                
                NSLog(@"UIEventSubtypeRemoteControlNextTrack");
                
                break;
                
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                
                NSLog(@"UIEventSubtypeRemoteControlPreviousTrack");
                
                break;
                
            case UIEventSubtypeRemoteControlPause:
                NSLog(@"UIEventSubtypeRemoteControlPause");
                break;
            case UIEventSubtypeRemoteControlPlay:
                NSLog(@"UIEventSubtypeRemoteControlPlay");
                break;
                
            default:
                break;
        }
    }
}

- (void)configNowPlayingInfoCenter {
    
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter) {
        
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        
        // 当前播放歌曲的图片
        //MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage: Default];
        
        NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:@"艺术家名", MPMediaItemPropertyArtist,
                                  @"歌曲名", MPMediaItemPropertyTitle,
                                  nil/*artwork*/, MPMediaItemPropertyArtwork,
                                  @"专辑名", MPMediaItemPropertyAlbumTitle,
                                  nil];
        center.nowPlayingInfo = songInfo;
        
        //[artwork release];
    }
}

@end
