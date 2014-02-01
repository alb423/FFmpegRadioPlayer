//
//  ViewController.h
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 13/4/19.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iAd/iAd.h"	
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#import "AudioPacketQueue.h"
#import "AudioPlayer.h"
#import "MyUtilities.h"

#define DEFAULT_BROADCAST_URL @"hinet_radio_json.json"
#define MMS_LIVENESS_CHECK_TIMER 1  // Seconds
#define AUDIO_BUFFER_TIME 1 //10 // Seconds

typedef enum eReplaySwitch {
    eReplaySwitch_On  = 0,
    eReplaySwitch_Off  = 1
}eReplaySwitch;

typedef enum eCacheSize {
    eCacheSize_Low     = 0,
    eCacheSize_Middle  = 1,
    eCacheSize_High    = 2
}eCacheSize;

typedef enum eAudioThreshold {
    eAudioThreshold_Low     = 10,
    eAudioThreshold_Middle  = 20,
    eAudioThreshold_High    = 30
}eAudioThreshold;

@interface ViewController : UIViewController <UIAlertViewDelegate, ADBannerViewDelegate>
{
	AVFormatContext *pFormatCtx;    
    AVCodecContext *pAudioCodecCtx;
    AVPacket packet;
    
    double audioClock;
    int audioStream;

    AudioPlayer *aPlayer;
    BOOL bIsStop;
    BOOL bIsLocalFile;

}

@property (weak, nonatomic) IBOutlet UIButton *PlayAudioButton;
@property (weak, nonatomic) IBOutlet UITableView *URLListView;
@property (strong, nonatomic) NSArray *URLListData;
@property (weak, nonatomic) IBOutlet UILabel *StationNameToDisplay;
@property (strong, nonatomic) IBOutlet UILabel *ProgramNameToDisplay;
@property (weak, nonatomic) IBOutlet UISlider *VolumeBar;
@property (strong, nonatomic) IBOutlet UILabel *AudioBufferLoadingLabel;
@property (strong, nonatomic) IBOutlet ADBannerView *pADBannerView;

- (IBAction)VolumeBarPressed:(id)sender;
- (IBAction)PlayAudio:(id)sender;
- (void)ProcessJsonDataForBroadCastURL:(NSData *)pJsonData;
-(void) setAudioBufferThreshold:(NSInteger )vThreshold;

- (void) saveStatus;
- (void) restoreStatus;


// 20130903 albert.liao modified start
@property BOOL bRecordStart;
//- (IBAction)VideoRecordPressed:(id)sender;
// 20130903 albert.liao modified end

@property (nonatomic) NSUInteger audioReplaySwitch;
@property (nonatomic) NSUInteger cacheSize;
@property (nonatomic) NSUInteger stopTimerMinutes;
@property (nonatomic) NSUInteger stopTimerHours;

@end
