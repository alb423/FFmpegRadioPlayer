//
//  ViewController.m
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 13/4/19.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//


#import "ViewController.h"
#import "Notifications.h"
#import <AVFoundation/AVFoundation.h>
#import "MediaPlayer/MPNowPlayingInfoCenter.h"
#import "MediaPlayer/MPMediaItem.h"
#import <Foundation/Foundation.h>

#import "AudioPlayer.h"
#import "AudioUtilities.h"


#import "GetRadioProgram.h"
#import "DailyProgramViewController.h"
#import "SettingsViewController.h"

//#import "NSCalendar.h"

#define WAV_FILE_NAME @"1.wav"

// If we read too fast, the size of aqQueue will increased quickly.
// If we read too slow, .
//#define LOCAL_FILE_DELAY_MS 80

// For 19_Austria.mp3
#define LOCAL_FILE_DELAY_MS 25

// Reference for AAC test file
// http://download.wavetlan.com/SVV/Media/HTTP/http-aac.htm
// http://download.wavetlan.com/SVV/Media/RTSP/darwin-aac.htm


// === LOCAL File ===
//#define AUDIO_TEST_PATH @"19_Austria.mp3"
//#define AUDIO_TEST_PATH @"AAC_12khz_Mono_5.aac"
//#define AUDIO_TEST_PATH @"test_mono_8000Hz_8bit_PCM.wav"
//#define AUDIO_TEST_PATH @"output.pcm"
    
// WMA Sample plz reference http://download.wavetlan.com/SVV/Media/HTTP/WMA/WindowsMediaPlayer/
//#define AUDIO_TEST_PATH @"WMP_Test11-WMA_WMA2_Mono_64kbps_44100Hz-Eric_Clapton-Wonderful_Tonight.WMA"
//#define AUDIO_TEST_PATH @"WMP_Test12 - WMA_WMA2_Stereo_64kbps_44100Hz - Eric_Clapton-Wonderful_Tonight.WMA"

// === MMS URL ===
// plz reference http://alyzq.com/?p=777
// Stereo, 64kbps, 48000Hz
#define AUDIO_TEST_PATH @"mms://bcr.media.hinet.net/RA000009"
//#define AUDIO_TEST_PATH @"mms://alive.rbc.cn/fm876"
// A error URL
//#define AUDIO_TEST_PATH @"mms://211.89.225.141/cnr001"

// === Valid RTSP URL ===
//#define AUDIO_TEST_PATH @"rtsp://216.16.231.19/BlackBerry.3gp"
//#define AUDIO_TEST_PATH @"rtsp://216.16.231.19/BlackBerry.mp4"
//#define AUDIO_TEST_PATH @"rtsp://mm2.pcslab.com/mm/7h800.mp4"
//#define AUDIO_TEST_PATH @"rtsp://216.16.231.19/The_Simpsons_S19E05_Treehouse_of_Horror_XVIII.3GP"


// === For Error Control Testing ===
// Test remote file
// Online Radio (can't play well)
//#define AUDIO_TEST_PATH @"rtsp://rtsplive.881903.com/radio-Web/cr2.3gp"

// Online Radio (invalid rtsp)
//#define AUDIO_TEST_PATH @"rtsp://211.89.225.101/live1"

// ("wma" audio format is not supported)
// #define AUDIO_TEST_PATH @"rtsp://media.iwant-in.net/pop"


// When unitest is selected, we should disable error prompt msgbox of UI
#define _UNITTEST_FOR_ALL_URL_ 0
#define _UNITTEST_PLAY_INTERVAL_ 30


@interface ViewController()
{

    UIActivityIndicatorView *pIndicator;
    NSTimer *vReConnectMMSServerTimer;
    NSTimer *vUpdateProgramTimer;
    NSTimer *vStopPlayTimer;
    
    NSString *pUserSelectedURL;
    NSInteger vUserSelectedIndex;
    NSInteger vAccessorySelected;
    NSString *pSelectedRadioStation;
    NSString *pCurrentRadioProgram;
    
    CGSize AudioButtonSize;
}
@end


@implementation ViewController
{
    NSInteger vAudioBufferThreshold;
    NSInteger vAudioBufferPacketCount;

    
#if _UNITTEST_FOR_ALL_URL_==1
    NSInteger vTestCase;
    NSString *pTestLog;
#endif
}

// 20130903 albert.liao modified start
@synthesize bRecordStart;
// 20130903 albert.liao modified end

@synthesize URLListData, StationNameToDisplay, ProgramNameToDisplay;
@synthesize VolumeBar, URLListView, pADBannerView, AudioBufferLoadingLabel;
@synthesize audioReplaySwitch, cacheSize, stopTimerHours, stopTimerMinutes;;


- (void) saveStatus
{
    [[NSUserDefaults standardUserDefaults] setInteger:audioReplaySwitch forKey:@"audioReplaySwitch"];
    [[NSUserDefaults standardUserDefaults] setInteger:cacheSize forKey:@"cacheSize"];
    [[NSUserDefaults standardUserDefaults] setInteger:stopTimerHours forKey:@"stopTimerHours"];
    [[NSUserDefaults standardUserDefaults] setInteger:stopTimerMinutes forKey:@"stopTimerMinutes"];
    [[NSUserDefaults standardUserDefaults]  synchronize];
}

- (void) restoreStatus
{
    audioReplaySwitch = [[NSUserDefaults standardUserDefaults] integerForKey:@"audioReplaySwitch"];
    cacheSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"cacheSize"];
    stopTimerHours = [[NSUserDefaults standardUserDefaults] integerForKey:@"stopTimerHours"];
    stopTimerMinutes = [[NSUserDefaults standardUserDefaults] integerForKey:@"stopTimerMinutes"];
}


-(NSInteger) getCurrentMinutes
{
    NSDate *today = [NSDate date];
    NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *dateComps = [gregorianCal components: (NSHourCalendarUnit | NSMinuteCalendarUnit)
                                                  fromDate: today];
    return (60 - [dateComps minute]);
}

-(void)UpdateProgramTimerFired:(NSTimer *)timer {
    //NSLog(@"func:%s line %d",__func__, __LINE__);
    if(timer!=nil)
    {
        NSLog(@"UpdateProgramTimerFired, setTimer to next hour");

        [self UpdateCurrentProgramName];
        vUpdateProgramTimer = [NSTimer scheduledTimerWithTimeInterval:3600                                                    target:self
                                                             selector:@selector(UpdateProgramTimerFired:)
                                                             userInfo:nil
                                                              repeats:NO];
    }
}


// 20130828 albert.liao modified start
-(void)reConnectMMSServer:(NSTimer *)timer {
    //NSLog(@"func:%s line %d",__func__, __LINE__);
    if(timer!=nil)
    {
        [timer invalidate];
        timer = nil;
        
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            // check the status of audio queue
            if([aPlayer getStatus]!=eAudioRunning)
        
            // check the status of ffmpeg streaming, ?????
            // if(bIsStop==TRUE)
            {
                NSLog(@"func:%s line %d",__func__, __LINE__);
                // Stop Audio

                [self StopPlayAudio:nil]; //_PlayAudioButton
            
                NSLog(@"func:%s line %d reconnect %@",__func__, __LINE__, pUserSelectedURL);
                [self PlayAudio:nil];
            }
        //});
    }
}
// 20130828 albert.liao modified end



- (void)ProcessJsonDataForBroadCastURL:(NSData *)pJsonData
{
    //parse out the json data
    NSError* error;
    
    NSMutableDictionary* jsonDictionary = [NSJSONSerialization JSONObjectWithData:pJsonData //1
                                                                          options:NSJSONReadingAllowFragments
                                                                            error:&error];
    if(error!=nil)
    {
        //NSString* aStr;
        //aStr = [[NSString alloc] initWithData:pJsonData encoding:NSUTF8StringEncoding];
        //NSLog(@"str=%@",aStr);
        
        NSLog(@"json transfer error %@", error);
        return;
        
    }
    
    // 1) retrieve the URL list into NSArray
    // A simple test of URLListData
    URLListData = [jsonDictionary objectForKey:@"url_list"];
    if(URLListData==nil)
    {
        NSLog(@"URLListData load error!!");
        return;
    }
    //NSLog(@"URLListData=%@",URLListData);
    
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    [self restoreStatus];
    // init 
    NSString *pAudioPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:DEFAULT_BROADCAST_URL];
    NSData *pJsonData = [[NSFileManager defaultManager] contentsAtPath:pAudioPath];
    //NSData* pJsonData = [NSData dataWithContentsOfFile:pAudioPath];
    
    //NSLog(@"jsondata : %@", pJsonData);
    [self ProcessJsonDataForBroadCastURL:pJsonData];
    pAudioPath=nil;
    pJsonData = nil;
    bIsStop = TRUE;
    
    // Show the default broadcast URL
    // TODO: the default broadcast URL should be assigned to the last used URL.
    NSDictionary *URLDict = [URLListData objectAtIndex:0];
    vUserSelectedIndex = 0;
    pUserSelectedURL = [URLDict valueForKey:@"url"];
    pSelectedRadioStation = [URLDict valueForKey:@"title"];
    StationNameToDisplay.text = [URLDict valueForKey:@"title"];
    ProgramNameToDisplay.text = nil;
    
    // init Volumen Bar
    VolumeBar.maximumValue = 1.0;
    VolumeBar.minimumValue = 0.0;
    VolumeBar.value = 0.5;
    VolumeBar.continuous = YES;
    [aPlayer SetVolume:VolumeBar.value];
    
    

    
#if _UNITTEST_FOR_ALL_URL_ == 1 // Unittest
    vTestCase = 0;
    pUserSelectedURL = [URLDict valueForKey:@"url"];
    pTestLog = [[NSString alloc]initWithString:pUserSelectedURL];
    [self PlayAudio:_PlayAudioButton];
    
    [NSTimer scheduledTimerWithTimeInterval:_UNITTEST_PLAY_INTERVAL_
                                       target:self
                                     selector:@selector(runNextTestCase:)
                                     userInfo:nil
                                      repeats:YES];
    
#endif
    
    
    // Do all Test here
    #if 0
    [GetRadioProgram GetRequest];
    #endif
    
    /*
     *  Listen for the appropriate notifications.
     */
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlPlayButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlPauseButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlStopButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlForwardButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlBackwardButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlOtherButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:remoteControlShowMessage object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:PlayButtonTapped object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:StopButtonTapped object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:audioBufferLoadingProgress object:nil];
    
    
    
    URLListView.pagingEnabled = false;
    
    pADBannerView.delegate = self;
    // For new iOS 7.0 only
    //self.canDisplayBannerAds = YES;
    
    vAudioBufferPacketCount = 0 ;
    vAudioBufferThreshold = 10;
    
    AudioButtonSize.height = 32;
    AudioButtonSize.width = 32;
    //AudioButtonSize = _PlayAudioButton.imageView.image.size;
    [AudioBufferLoadingLabel setText:@""];
    [_PlayAudioButton sizeThatFits:AudioButtonSize];
    
    // TODO : use SCNetworkReachabilityRef to dectect 3G or WIFI
    return;
}

- (void)dealloc
{
    ;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
}


- (IBAction)StopPlayAudio:(id)sender {

    // The reconnect timer should stop earilier to avoid restart when stop play audio.
    [vReConnectMMSServerTimer invalidate];
    [vUpdateProgramTimer invalidate];
    vReConnectMMSServerTimer = nil;
    vUpdateProgramTimer = nil;

    
#if 0
    // Stop Consumer
    [aPlayer Stop:TRUE];
    aPlayer= nil;
    
    // Stop Producer
    [self stopFFmpegAudioStream];
    [self destroyFFmpegAudioStream];
    
#else
    // To avoid the memory leakage of AudioPacketQueue
    
    // Stop Producer
    [self stopFFmpegAudioStream];
    
    // Stop Consumer
    [aPlayer Stop:TRUE];
    aPlayer= nil;

    [self destroyFFmpegAudioStream];
#endif
    
    [[AVAudioSession sharedInstance] setActive:NO error:nil];
}

- (void) UpdateCurrentProgramName
{
    NSDictionary *URLDict = [URLListData objectAtIndex:vUserSelectedIndex];
    NSString *pRaidoId = [URLDict valueForKey:@"id"];
    NSString *pMyDateString;
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    pMyDateString = [dateFormatter stringFromDate:now];
    
    // For different country, the program URL may be different
    // This is for taiwan only
    NSString *pRadioProgramUrl = [[NSString alloc]initWithFormat:@"http://hichannel.hinet.net/ajax/radio/program.do?id=%s&date=%s",
                                  [pRaidoId UTF8String],
                                  [pMyDateString UTF8String]];
    
    
    NSArray *pProgram=[NSArray alloc];
    NSData* pJsonData;
    
    if(pUserSelectedURL==nil)
    {
        pUserSelectedURL = AUDIO_TEST_PATH;
    }
    pJsonData = [NSData dataWithContentsOfURL: [NSURL URLWithString:pRadioProgramUrl]];
    pProgram = [GetRadioProgram parseJsonData:pJsonData];
    
    // Get the current active program
    int i;
    for(i=0;i<[pProgram count];i++)
    {
        NSDictionary *pItem = [pProgram objectAtIndex:i];
        NSString *pOn = [[NSString alloc] initWithFormat:@"%@",[pItem valueForKey:@"on"]] ;
        if( [pOn integerValue] == 1)
            pCurrentRadioProgram = [pItem valueForKey:@"programName"];
    }
    ProgramNameToDisplay.text = pCurrentRadioProgram;
}

-(void) setAudioBufferThreshold:(NSInteger )vThreshold{
    vAudioBufferThreshold = vThreshold;
}


-(void)StopTimerFired:(NSTimer *)timer {
    NSLog(@"StopTimerFired");
    if(aPlayer)
    {
        [self StopPlayAudio:nil];
    }
    
    if(timer!=nil)
    {
        [timer invalidate];
        timer = nil;
    }
}


- (IBAction)PlayAudio:(id)sender {
    
    UIButton *vBn = (UIButton *)sender;
    
    if(vBn==nil)
       vBn = _PlayAudioButton;
    
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
#if 0
    NSString *pAudioInPath;
    pAudioInPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:AUDIO_TEST_PATH];
    [AudioUtilities initForDecodeAudioFile:pAudioInPath ToPCMFile:@"/Users/liaokuohsun/1.wav"];
    NSLog(@"Save file to /Users/liaokuohsun/1.wav");
    return;
#endif
    
    if(bIsStop==false)
    {
        [self StopPlayAudio:nil];
        //[vBn setTitle:@"Play" forState:UIControlStateNormal];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"StopButtonTapped" object:self];
    }
    else
    {
        //[vBn setTitle:@"Stop" forState:UIControlStateNormal];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayButtonTapped" object:self];
        
        [self UpdateCurrentProgramName];
        
        //[self performSelectorOnMainThread:@selector(parseJsonData:) w waitUntilDone:YES];
        
//        dispatch_async(dispatch_get_main_queue(), ^(void) {
//            @autoreleasepool {
//                [MyUtilities showWaiting:self.view];
//            }
//        });
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            {
                if([self initFFmpegAudioStream]==FALSE)
                {
                    NSLog(@"initFFmpegAudio fail");
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        //@autoreleasepool
                        {
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"StopButtonTapped" object:self];
                            //[MyUtilities hideWaiting:self.view];
        #if _UNITTEST_FOR_ALL_URL_ == 1
                            pTestLog = [pTestLog stringByAppendingString:@" RTSP Fail\n"];
        #else
                            // TODO: this part may need revise
                            UIAlertView *pErrAlertView = [[UIAlertView alloc] initWithTitle:@"\n\nRTSP error"
                                                                                    message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
                            [pErrAlertView show];
                            pErrAlertView = nil;
        #endif
                        }
                    });
                    return;
                }
                
                // pAudioCodecCtx is active only when initFFmpegAudioStream is success
                if(aPlayer==nil)
                {
                    aPlayer = [[AudioPlayer alloc]initAudio:nil withCodecCtx:(AVCodecContext *) pAudioCodecCtx];
                    
                }
                
                NSDate *today = [NSDate date];
                NSCalendar *gregorianCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
                NSDateComponents *dateComps = [gregorianCal components: (NSHourCalendarUnit | NSMinuteCalendarUnit)
                                                              fromDate: today];
                
                
                NSInteger checkTime = (60 - [dateComps minute])*60;

                dispatch_async(dispatch_get_main_queue(), ^(void) {
                    vUpdateProgramTimer = [NSTimer scheduledTimerWithTimeInterval:checkTime                                                    target:self
                                               selector:@selector(UpdateProgramTimerFired:)
                                               userInfo:nil
                                                repeats:NO];
                    
                    NSInteger vStopTime = stopTimerHours*60+stopTimerMinutes;
                    if(vStopTime!=0)
                    {
                        vStopPlayTimer = [NSTimer scheduledTimerWithTimeInterval:vStopTime                                               target:self
                                                        selector:@selector(StopTimerFired:)
                                                                         userInfo:nil
                                                                          repeats:NO];
                    }
                });
                
                NSLog(@"== readFFmpegAudioFrameAndDecode");
                [self readFFmpegAudioFrameAndDecode];
            }
        });
    }
}


#pragma mark - ffmpeg usage
-(BOOL) initFFmpegAudioStream{
    
    NSString *pAudioInPath;
    AVCodec  *pAudioCodec;
    AVDictionary *opts = 0;
    
    // 20130428 Test here
#if 0
    {
        // Test sample :http://m.oschina.net/blog/89784
        uint8_t pInput[] = {0x0ff,0x0f9,0x058,0x80,0,0x1f,0xfc};
        tAACADTSHeaderInfo vxADTSHeader={0};        
        [AudioUtilities parseAACADTSHeader:pInput ToHeader:(tAACADTSHeaderInfo *) &vxADTSHeader];
    }
#endif
    
    // The pAudioInPath should be set when user select a url
    if(pUserSelectedURL==nil)
    {
        // use default url for testing
        pAudioInPath = AUDIO_TEST_PATH;
    }
    else
    {
        pAudioInPath = pUserSelectedURL;
    }
        
    if( strncmp([pAudioInPath UTF8String], "rtsp", 4)==0)
    {
        av_dict_set(&opts, "rtsp_transport", "tcp", 0); // can set "udp", "tcp", "http"
        bIsLocalFile = FALSE;
    }
    else if( strncmp([pAudioInPath UTF8String], "mms:", 4)==0)
    {
        //replace "mms:" to "mmsh:" or "mmst:"
        av_dict_set(&opts, "rtsp_transport", "http", 0); // can set "udp", "tcp", "http"
        pAudioInPath = [pAudioInPath stringByReplacingOccurrencesOfString:@"mms:" withString:@"mmsh:"];
//pAudioInPath = [pAudioInPath stringByReplacingOccurrencesOfString:@"mms:" withString:@"mmst:"];
        //NSLog(@"pAudioPath=%@", pAudioInPath);
        bIsLocalFile = FALSE;
    }
    else if( strncmp([pAudioInPath UTF8String], "mmsh", 4)==0)
    {
        av_dict_set(&opts, "rtsp_transport", "http", 0);
        bIsLocalFile = FALSE;
    }
    else
    {
        av_dict_set(&opts, "rtsp_transport", "udp", 0);
        pAudioInPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:AUDIO_TEST_PATH];
        bIsLocalFile = TRUE;
    }
        
    avcodec_register_all();
    av_register_all();
    av_log_set_level(AV_LOG_VERBOSE);
    if(bIsLocalFile!=TRUE)
    {
        avformat_network_init();
    }
    
    @synchronized(self)
    {
        pFormatCtx = avformat_alloc_context();
    }
    
#if 1 // TCP
    //av_dict_set(&opts, "rtsp_transport", "tcp", 0);
    NSLog(@"pAudioInPath=%@", pAudioInPath);
    
    // Open video file
    if(avformat_open_input(&pFormatCtx, [pAudioInPath cStringUsingEncoding:NSASCIIStringEncoding], NULL, &opts) != 0) {

        if( strncmp([pAudioInPath UTF8String], "mmst", 4)==0)
        {
            av_log(NULL, AV_LOG_ERROR, "Couldn't open mmst connection\n");
            pAudioInPath= [pAudioInPath stringByReplacingOccurrencesOfString:@"mmst:" withString:@"mmsh:"];
            if(avformat_open_input(&pFormatCtx, [pAudioInPath cStringUsingEncoding:NSASCIIStringEncoding], NULL, &opts) != 0)
            {
                av_log(NULL, AV_LOG_ERROR, "Couldn't open mmsh connection to %s\n", [pAudioInPath UTF8String]);
                return FALSE;
            }
        }
        else
        {
            av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");            
            return FALSE;
        }
    }
    
	av_dict_free(&opts);
    
#else // UDP
    if(avformat_open_input(&pFormatCtx, [pAudioInPath cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL) != 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
        return FALSE;
    }
#endif
    
    pAudioInPath = nil;
    
    // Retrieve stream information
    if(avformat_find_stream_info(pFormatCtx,NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find stream information\n");
        return FALSE;
    }
    
    // Dumpt stream information
    av_dump_format(pFormatCtx, 0, [pAudioInPath UTF8String], 0);
    
    
    // 20130329 albert.liao modified start
    // Find the first audio stream
    if ((audioStream =  av_find_best_stream(pFormatCtx, AVMEDIA_TYPE_AUDIO, -1, -1, &pAudioCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a audio stream in the input file\n");
        return FALSE;
    }
	
    if(audioStream>=0){
        
        NSLog(@"== Audio pCodec Information ==");
        NSLog(@"name = %s, stream_num = %d",pAudioCodec->name, audioStream);
        NSLog(@"sample_fmts = %d",*(pAudioCodec->sample_fmts));
        if(pAudioCodec->profiles)
        {
            NSLog(@"profiles = %s",pAudioCodec->name);
        }
        else
        {
            NSLog(@"profiles = NULL");
        }
        
        // Get a pointer to the codec context for the video stream
        pAudioCodecCtx = pFormatCtx->streams[audioStream]->codec;
        
        // Find the decoder for the video stream
        pAudioCodec = avcodec_find_decoder(pAudioCodecCtx->codec_id);
        if(pAudioCodec == NULL) {
            av_log(NULL, AV_LOG_ERROR, "Unsupported audio codec!\n");
            return FALSE;
        }
        
        // Open codec
        if(avcodec_open2(pAudioCodecCtx, pAudioCodec, NULL) < 0) {
            av_log(NULL, AV_LOG_ERROR, "Cannot open audio decoder\n");
            return FALSE;
        }
        
    }
    
    bIsStop = FALSE;
    
    return TRUE;
}

-(void) stopFFmpegAudioStream{
    @synchronized(self)
    {
        bIsStop = TRUE;
    }
    NSLog(@"stopFFmpegAudioStream");
}

-(void) destroyFFmpegAudioStream{
    bIsStop = TRUE;
    NSLog(@"destroyFFmpegAudioStream");

    avformat_network_deinit();

    if (pAudioCodecCtx) {
        avcodec_close(pAudioCodecCtx);
        // If we create pAudioCodecCtx ourself, we should free it.
        //av_free(pAudioCodecCtx);
        pAudioCodecCtx = NULL;
    }
    if (pFormatCtx) {
        avformat_close_input(&pFormatCtx);
    }

}


-(void) readFFmpegAudioFrameAndDecode {
    int vErr;
    AVPacket vxPacket;
    av_init_packet(&vxPacket);    
    
    if(bIsLocalFile == TRUE)
    {
        while(bIsStop==FALSE)
        {
            vErr = av_read_frame(pFormatCtx, &vxPacket);
            NSLog(@"av_read_frame");
            if(vErr>=0)
            {
                if(vxPacket.stream_index==audioStream) {
                    
#if 1
                    AVPacket vxPacket2;
                    vxPacket2.size = vxPacket.size;
                    vxPacket2.data = malloc(vxPacket2.size+FF_INPUT_BUFFER_PADDING_SIZE);
                    memset(vxPacket2.data, 0, vxPacket2.size+FF_INPUT_BUFFER_PADDING_SIZE);
                    memcpy(vxPacket2.data, vxPacket.data, vxPacket2.size);
                    int ret = [aPlayer putAVPacket:&vxPacket2];
                    if(ret <= 0)
                        NSLog(@"Put Audio Packet Error 1!!");
                    
//                    if (vxPacket.data)
//                        av_freep(vxPacket.data);
                    av_free_packet(&vxPacket);
#else
                    int ret = [aPlayer putAVPacket:&vxPacket];
                    if(ret <= 0)
                        NSLog(@"Put Audio Packet Error 2!!");
                    if (vxPacket.data)
                        av_freep(vxPacket.data);
                    av_free_packet(&vxPacket);
#endif

                    
                    
                    // TODO: use pts/dts to decide the delay time 
                    usleep(1000*LOCAL_FILE_DELAY_MS);
                }
                else
                {
                    //NSLog(@"receive unexpected packet!!");
                    if (vxPacket.data)
                        av_freep(vxPacket.data);
                    av_free_packet(&vxPacket);
                }
            }
            else
            {
                NSLog(@"av_read_frame error :%s", av_err2str(vErr));
                bIsStop = TRUE;
                break;
            }
        }
    }
    else
    {
        // NOTE: some url may have dual audio stream,
        // For example: mmsh://bcr.media.hinet.net/RA000038
        while(1)
        {
            @synchronized(self)
            {
                if(bIsStop==TRUE)
                {
                    // If vxPacket is read from ffmpeg. av_free_packet() will free vxPacket.data too.
                    NSLog(@"***FFMPEG Stop read frame");
                    break;
                }
                vErr = av_read_frame(pFormatCtx, &vxPacket);
            }
            
            if(vErr==AVERROR_EOF)
            {
                NSLog(@"av_read_frame error :%s", av_err2str(vErr));
                bIsStop = TRUE;
            }
            else if(vErr==0)
            {
                if(vxPacket.stream_index==audioStream) {
                    
//                    AVPacket vxPacket2;
//                    vxPacket2.size = vxPacket.size;
//                    vxPacket2.data = malloc(vxPacket2.size+FF_INPUT_BUFFER_PADDING_SIZE);
//                    memset(vxPacket2.data, 0, vxPacket2.size+FF_INPUT_BUFFER_PADDING_SIZE);
//                    memcpy(vxPacket2.data, vxPacket.data, vxPacket.size);
                    if(aPlayer==nil)
                        break;
                    
                    int ret = [aPlayer putAVPacket:&vxPacket];
                    if(ret <= 0)
                    {
                        NSLog(@"Put Audio Packet Error 3!!");
                    }
                    
                    //av_free_packet(&vxPacket);
                }
                else
                {
//                    int i=0;
//                    NSLog(@"receive unexpected packet, size=%d!!", vxPacket.size);
//                    for(i=0;i<vxPacket.size;i+=7)
//                    {
//                        if(vxPacket.size-i>=8)
//                        {
//                        NSLog(@"%02X%02X%02X%02X %02X%02X%02X%02X ",\
//                              vxPacket.data[i],vxPacket.data[i+1],vxPacket.data[i+2],vxPacket.data[i+3],
//                              vxPacket.data[i+4],vxPacket.data[i+5],vxPacket.data[i+6],vxPacket.data[i+7]);
//                        }
//                    }
                    if (vxPacket.data)
                        free(vxPacket.data);
                    av_free_packet(&vxPacket);
                }
            }
            else
            {
                NSLog(@"av_read_frame error :%s", av_err2str(vErr));
                bIsStop = TRUE;
                break;
            }
            
            // audio play callback
            //if(vPktCount<10) //<10 // The voice is listened after image is rendered
            //if([aPlayer getCount]<=10)
            
            // AudioBufferLoadingProgress
            
            vAudioBufferPacketCount = [aPlayer getCount];

            
            if(vAudioBufferPacketCount<=vAudioBufferThreshold)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:audioBufferLoadingProgress object:self];
                //NSLog(@"[aPlayer getCount]=%d",vAudioBufferPacketCount);
            }
            else
            {
                if(aPlayer!=nil)
                {
                    if([aPlayer getStatus]!=eAudioRunning)
                    {
                        [aPlayer Play];
                    }
                }
            }
        }
    }
    
    
    
    NSLog(@"Leave ReadFrame");
}

#pragma mark - Recording Control
#if 0
- (IBAction)VideoRecordPressed:(id)sender {
    
    if(bRecordStart==true)
    {
        bRecordStart = false;
        [aPlayer RecordingStop];
    }
    else
    {
        // set recording format
        //vRecordingAudioFormat = kAudioFormatLinearPCM;// (Test ok)
        //vRecordingAudioFormat = kAudioFormatMPEG4AAC; //(need Test)
        bRecordStart = true;
#if 0
        [aPlayer RecordingSetAudioFormat:kAudioFormatLinearPCM];        
        [aPlayer RecordingStart:@"/Users/liaokuohsun/2.wav"];
#else
        [aPlayer RecordingSetAudioFormat:kAudioFormatMPEG4AAC];
        //[aPlayer RecordingStart:@"/Users/liaokuohsun/Audio2.mp4"];
        [aPlayer RecordingStart:@"/Users/miuki001/Audio2.mp4"];
        //[aPlayer RecordingStart:@"/Users/liaokuohsun/Audio2.m4a"];
#endif
    }
}
#endif

#pragma mark - URL_list TableView

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSLog(@"[URLListData count]=%d",[URLListData count]);
    return [URLListData count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *tableIdentifier = @"Simple table";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:tableIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:tableIdentifier];
        //NSLog(@"alloc cell size %ld",sizeof(cell));
    }
    
    NSDictionary *URLDict = [URLListData objectAtIndex:indexPath.row];
    cell.textLabel.text = [URLDict valueForKey:@"title"];
    cell.accessoryType = UITableViewCellAccessoryDetailButton;
    //cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
    URLDict = nil;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the URL_TO_PLAY to the url user select
    NSDictionary *URLDict = [URLListData objectAtIndex:indexPath.row];
    
    vUserSelectedIndex = indexPath.row;
    pUserSelectedURL = nil;
    pUserSelectedURL = [URLDict valueForKey:@"url"];
    pSelectedRadioStation = [URLDict valueForKey:@"title"];
    
    StationNameToDisplay.text = pSelectedRadioStation;
    StationNameToDisplay.textAlignment = NSTextAlignmentCenter;
    
    URLDict = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^(void){
        // Start Play when user select the row
        if([aPlayer getStatus]==eAudioRunning)
            [self StopPlayAudio:_PlayAudioButton];
        [self PlayAudio:_PlayAudioButton];
    });
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    vAccessorySelected = indexPath.row;
    [self performSegueWithIdentifier:@"ShowDailyProgram" sender:self.view];
}


#pragma mark - segue control

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSLog(@"prepareForSegue");
    
    if([[segue identifier] isEqualToString:@"ShowDailyProgram"])
    {
        NSDictionary *URLDict = [URLListData objectAtIndex:vAccessorySelected];
        NSString *pRaidoId = [URLDict valueForKey:@"id"];

        NSString *pUrlTemplate = [[NSString alloc]initWithFormat:@"http://hichannel.hinet.net/ajax/radio/program.do?id=%s&date=",
                          [pRaidoId UTF8String]];
        
        DailyProgramViewController *pDailyProgramViewController = [segue destinationViewController];
        [pDailyProgramViewController setValue:pUrlTemplate forKey:@"pRadioProgramUrlTemplate"];
        [pDailyProgramViewController setValue:pSelectedRadioStation forKey:@"pRadioProgramName"];
        //[pDailyProgramViewController.navigationItem setTitle:pSelectedRadioStation];
        
    }
    else if([[segue identifier] isEqualToString:@"Settings"])
    {
        SettingsViewController *dstViewController = [segue destinationViewController];
        dstViewController.pViewController = self;
        ;
    }
    
}

#pragma mark - volume_bar Slider
- (IBAction)VolumeBarPressed:(id)sender {
    [aPlayer SetVolume:VolumeBar.value];
}


#pragma mark - ad_banner_view
- (BOOL) allowActionToRun
{
    return YES;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    NSLog(@"didFailToReceiveAdWithError");
    //NSLog(@"didFailToReceiveAdWithError:%@",error);
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


#pragma mark - test case callback

#if _UNITTEST_FOR_ALL_URL_==1
-(void)runNextTestCase:(NSTimer *)timer {
    if(timer!=nil)
    {
        [self StopPlayAudio:nil];
        
        vTestCase++;
        if(vTestCase==[URLListData count])
        {
            [timer invalidate];
            pTestLog = [pTestLog stringByAppendingString:@"\nFinished"];
            NSLog(@"%@", pTestLog);
            return;
        }
        else
        {
            NSDictionary *URLDict = [URLListData objectAtIndex:vTestCase];
            indexPath.row = vTestCase;
            pUserSelectedURL = [URLDict valueForKey:@"url"];
            pTestLog = [pTestLog stringByAppendingFormat:@"\ntest %@",pUserSelectedURL];
            [self PlayAudio:_PlayAudioButton];
        }
    }
}
#endif

#pragma mark - Remote Handling

/*  This method logs out when a
 *  remote control button is pressed.
 *
 *  In some cases, it will also manipulate the stream.
 */

- (void)handleNotification:(NSNotification *)notification
{
    if ([notification.name isEqualToString:remoteControlPlayButtonTapped]) {
        [self updateLogWithMessage:NSLocalizedString(@"Play remote event recieved.", @"A log event for play events.")];
        [self PlayAudio:self];
        
    } else  if ([notification.name isEqualToString:remoteControlPauseButtonTapped]) {
        [self updateLogWithMessage:NSLocalizedString(@"Pause remote event recieved.", @"A log event for pause events.")];
        // TODO: if we destroy the audio queue, the play menu will destroy,too
        [self StopPlayAudio:self];
        
    } else if ([notification.name isEqualToString:remoteControlStopButtonTapped]) {
        [self updateLogWithMessage:NSLocalizedString(@"Stop remote event recieved.", @"A log event for stop events.")];
        [self StopPlayAudio:self];
        
    } else if ([notification.name isEqualToString:remoteControlForwardButtonTapped]) {
        [self updateLogWithMessage:NSLocalizedString(@"Forward remote event recieved.", @"A log event for next events.")];
        
    } else if ([notification.name isEqualToString:remoteControlBackwardButtonTapped]) {
        [self updateLogWithMessage:NSLocalizedString(@"Back remote event recieved.", @"A log event for back events.")];
        
    } else if ([notification.name isEqualToString:remoteControlShowMessage]) {
        [self configNowPlayingInfoCenter];

    } else if ([notification.name isEqualToString:PlayButtonTapped]) {
        UIImage * myImage = [UIImage imageNamed: @"Stop.png"];
        [_PlayAudioButton setImage:myImage  forState:UIControlStateNormal];
        [_PlayAudioButton sizeThatFits:AudioButtonSize];
        

    } else if ([notification.name isEqualToString:StopButtonTapped]) {
        UIImage * myImage = [UIImage imageNamed: @"Play.png"];
        [_PlayAudioButton setImage:myImage forState:UIControlStateNormal];
        [_PlayAudioButton sizeThatFits:AudioButtonSize];
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [AudioBufferLoadingLabel setText:@""];
        });
    } else if ([notification.name isEqualToString:audioBufferLoadingProgress]) {
        // TODO: the text change may blink
        int vProgress = vAudioBufferPacketCount*100/vAudioBufferThreshold;
        NSString *pBuffer = NSLocalizedString(@"Buffer",@"test" );
        NSLog(@"pBuffer=%@",pBuffer);
        NSString *pText;
        if(vProgress<100)
        {
            pText = [[NSString alloc]initWithFormat:@"%@:%d%%",NSLocalizedString(@"Buffer",@"test" ), vProgress];
        }
        else
        {
            pText = NSLocalizedString(@"Playing",@"test" );
        }
        
        NSLog(@"%@",pText );
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [AudioBufferLoadingLabel setText:pText];
        });
        
    } else {
        
        if ([notification.name isEqualToString:beginInterruption]) {
            if(audioReplaySwitch==eReplaySwitch_On)
            {
                [self StopPlayAudio:self];
            }
        }
        else  if ([notification.name isEqualToString:endInterruptionWithFlags]) {
            if(audioReplaySwitch==eReplaySwitch_On)
            {
                [self PlayAudio:self];
            }
        }
        else
        {
        [self updateLogWithMessage:NSLocalizedString(@"Unknown remote event recieved.", @"A log event for unknown events.")];
        }
    }
    
}

- (void)updateLogWithMessage:(NSString *)message
{
    NSLog(@"Log:%@",message);
//    if ([self.log.text isEqualToString:self.initialText]) {
//        self.log.text = [NSMutableString stringWithFormat:@"%@: %@", [NSDate date], message];
//    }
//    else {
//        self.log.text = [NSMutableString stringWithFormat:@"%@\n%@: %@", self.log.text, [NSDate date], message];
//    }
}

#pragma mark - playingInfoCenter

- (void)configNowPlayingInfoCenter {
    NSLog(@"configNowPlayingInfoCenter In");
    Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (playingInfoCenter) {
        
        MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
        
        // 当前播放歌曲的图片
//        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage alloc]ini
                                       //@"Default-iphone.png"];
        
        NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:pSelectedRadioStation, MPMediaItemPropertyArtist,
                                  pCurrentRadioProgram, MPMediaItemPropertyTitle,
                                  nil, MPMediaItemPropertyArtwork,
                                  nil, /*@"专辑名"*/ MPMediaItemPropertyAlbumTitle,
                                  nil];
        center.nowPlayingInfo = songInfo;
        
        //[artwork release];
    }
}

@end
