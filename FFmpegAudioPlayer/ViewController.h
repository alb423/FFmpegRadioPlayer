//
//  ViewController.h
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 13/4/19.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#import "AudioPacketQueue.h"
#import "AudioPlayer.h"
#import "MyUtilities.h"

#define DEFAULT_BROADCAST_URL @"hinet_radio_json.json"
#define MMS_LIVENESS_CHECK_TIMER 1  // Seconds
#define AUDIO_BUFFER_TIME 1 //10 // Seconds

//ADBannerViewDelegate
@interface ViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UIAlertViewDelegate>
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

- (IBAction)PlayTimerButtonPressed:(id)sender;
- (IBAction)VolumeBarPressed:(id)sender;
- (IBAction)PlayAudio:(id)sender;
- (void)ProcessJsonDataForBroadCastURL:(NSData *)pJsonData;

// 20130903 albert.liao modified start
@property BOOL bRecordStart;
//- (IBAction)VideoRecordPressed:(id)sender;
// 20130903 albert.liao modified end

@end
