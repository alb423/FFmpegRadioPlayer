//
//  ViewController.m
//  FFmpegAudioPlayer
//
//  Created by Liao KuoHsun on 13/4/19.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//


#import "ViewController.h"
#import "AudioPlayer.h"
#import "AudioUtilities.h"

#import "iAd/iAd.h"
//#import "iAd/ADBannerView.h"
#import "GetRadioProgram.h"

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

@interface ViewController () <ADBannerViewDelegate>{

    UIActivityIndicatorView *pIndicator;
    NSTimer *vReConnectMMSServerTimer;
    
    NSString *pUserSelectedURL;
    UIPickerView *PlayTimePickerView;
}
@end


@implementation ViewController
{
    NSInteger vPlayTimerSecond, vPlayTimerMinute;
    NSArray *PlayTimerSecondOptions;
    NSArray *PlayTimerMinuteOptions;

    dispatch_queue_t    ffmpegDispatchQueue;
    dispatch_queue_t    aPlayerDispatchQueue;
    __block dispatch_semaphore_t vDispatchQueueSem;
    
#if _UNITTEST_FOR_ALL_URL_==1
    NSInteger vTestCase;
    NSString *pTestLog;
#endif
}

// 20130903 albert.liao modified start
@synthesize bRecordStart;
// 20130903 albert.liao modified end

@synthesize URLListData, URLNameToDisplay, VolumeBar;



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
            dispatch_async(aPlayerDispatchQueue, ^(void)
            {
                NSLog(@"func:%s line %d",__func__, __LINE__);
                // Stop Audio

                [self StopPlayAudio:nil]; //_PlayAudioButton
            
                NSLog(@"func:%s line %d reconnect %@",__func__, __LINE__, pUserSelectedURL);
                [self PlayAudio:nil];
    });
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
    pUserSelectedURL = [URLDict valueForKey:@"url"];
    URLNameToDisplay.text = [URLDict valueForKey:@"title"];
    
    // init Volumen Bar
    VolumeBar.maximumValue = 1.0;
    VolumeBar.minimumValue = 0.0;
    VolumeBar.value = 0.5;
    VolumeBar.continuous = YES;
    [aPlayer SetVolume:VolumeBar.value];
    
    
    // init PlayTimer options
    PlayTimerSecondOptions = [[NSArray alloc]initWithObjects:@"0",@"5",@"10",@"15",@"20",@"25",@"30",@"35",@"40",@"45",@"50",@"55",@"60",nil];
    PlayTimerMinuteOptions = [[NSArray alloc]initWithObjects:@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",nil];

    
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
    
    // For new iOS 7.0 only
    //self.canDisplayBannerAds = YES;
    [super viewDidLoad];
    
    // TODO : use SCNetworkReachabilityRef to dectect 3G or WIFI
    return;
}

- (void)dealloc
{
    ffmpegDispatchQueue=nil;
    aPlayerDispatchQueue=nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"didReceiveMemoryWarning");
}


- (IBAction)StopPlayAudio:(id)sender {

    // The reconnect timer should stop earilier to avoid restart when stop play audio.
    [vReConnectMMSServerTimer invalidate];
    vReConnectMMSServerTimer = nil;
    
    // Stop Consumer
    if(aPlayerDispatchQueue)
    {
        dispatch_async(aPlayerDispatchQueue, ^(void) {
            [aPlayer Stop:TRUE];
            aPlayer = nil;
        });
    }
    
    // Stop Producer
    [self stopFFmpegAudioStream];
    [self destroyFFmpegAudioStream];
    
//    if(ffmpegDispatchQueue)
//    {
//        dispatch_async(ffmpegDispatchQueue, ^(void) {
//            [self stopFFmpegAudioStream];
//            [self destroyFFmpegAudioStream];
//        });
//    }

//    ffmpegDispatchQueue = nil;
//    aPlayerDispatchQueue=nil;
    
}

- (IBAction)PlayAudio:(id)sender {
    
    UIButton *vBn = (UIButton *)sender;
    
    if(vBn==nil)
       vBn = _PlayAudioButton;
    
    if(!ffmpegDispatchQueue)
        ffmpegDispatchQueue  = dispatch_queue_create("ffmpegDispatchQueue", DISPATCH_QUEUE_SERIAL);
    if(!aPlayerDispatchQueue)
        aPlayerDispatchQueue  = dispatch_queue_create("aPlayerDispatchQueue", DISPATCH_QUEUE_SERIAL);
    
    vDispatchQueueSem = dispatch_semaphore_create(0);
    
#if 0
    NSString *pAudioInPath;
    pAudioInPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:AUDIO_TEST_PATH];
    [AudioUtilities initForDecodeAudioFile:pAudioInPath ToPCMFile:@"/Users/liaokuohsun/1.wav"];
    NSLog(@"Save file to /Users/liaokuohsun/1.wav");
    return;
#endif
    
    if(bIsStop==false)
    {
        [vBn setTitle:@"Play" forState:UIControlStateNormal];
        //dispatch_async(dispatch_get_main_queue(), ^(void){
        //dispatch_async(ffmpegDispatchQueue, ^(void) {
        //    @autoreleasepool
            {
                [self StopPlayAudio:nil];
            }
        //});
        //[self StopPlayAudio:nil];
    }
    else
    {
        [vBn setTitle:@"Stop" forState:UIControlStateNormal];
        
//        dispatch_async(dispatch_get_main_queue(), ^(void) {
//            @autoreleasepool {
//                [MyUtilities showWaiting:self.view];
//            }
//        });
        
        dispatch_async(ffmpegDispatchQueue, ^(void) {
            @autoreleasepool
            {
                if([self initFFmpegAudioStream]==FALSE)
                {
                    NSLog(@"initFFmpegAudio fail");
                    dispatch_async(dispatch_get_main_queue(), ^(void) {
                        @autoreleasepool
                        {
                            [vBn setTitle:@"Play" forState:UIControlStateNormal];
                            [MyUtilities hideWaiting:self.view];
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
                    dispatch_semaphore_signal(vDispatchQueueSem);
                    return;
                }
                dispatch_semaphore_signal(vDispatchQueueSem);
            }
        });
        
        
        dispatch_semaphore_wait(vDispatchQueueSem, DISPATCH_TIME_FOREVER);
        
        // pAudioCodecCtx is active only when initFFmpegAudioStream is success
        dispatch_async(aPlayerDispatchQueue, ^(void) {
            //@autoreleasepool
            {
                if(aPlayer==nil)
                {
                    aPlayer = [[AudioPlayer alloc]initAudio:nil withCodecCtx:(AVCodecContext *) pAudioCodecCtx];
//                        aPlayer = [[AudioPlayer alloc]initAudio:nil
//                                                    withCodecId:pAudioCodecCtx->codec_id
//                                                 withSampleRate:pAudioCodecCtx->sample_rate
//                                                   withChannels:pAudioCodecCtx->channels
//                                                withFrameLength:pAudioCodecCtx->frame_size];

                }
                dispatch_semaphore_signal(vDispatchQueueSem);
                NSLog(@"== AudioPlayer alloc");
            }
        });
        
        
//        dispatch_async(dispatch_get_main_queue(), ^(void) {
//            @autoreleasepool {
//               [MyUtilities hideWaiting:self.view];
//            }
//        });

        dispatch_semaphore_wait(vDispatchQueueSem, DISPATCH_TIME_FOREVER);        
        dispatch_async(ffmpegDispatchQueue, ^(void) {
            @autoreleasepool
            {
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
    static int vPktCount=0;
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
                vPktCount = 0;
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
                    av_free_packet(&vxPacket);
                    vPktCount = 0;
                    break;
                }
                vErr = av_read_frame(pFormatCtx, &vxPacket);
            }
            
            if(vErr==AVERROR_EOF)
            {
                NSLog(@"av_read_frame error :%s", av_err2str(vErr));
                bIsStop = TRUE;
                vPktCount = 0;
            }
            else if(vErr==0)
            {
                if(vxPacket.stream_index==audioStream) {
                    
//                    AVPacket vxPacket2;
//                    vxPacket2.size = vxPacket.size;
//                    vxPacket2.data = malloc(vxPacket2.size+FF_INPUT_BUFFER_PADDING_SIZE);
//                    memset(vxPacket2.data, 0, vxPacket2.size+FF_INPUT_BUFFER_PADDING_SIZE);
//                    memcpy(vxPacket2.data, vxPacket.data, vxPacket.size);
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
                vPktCount = 0;
                break;
            }
            
            // audio play callback
            //NSLog(@"vPktCount=%d",vPktCount);
            if(vPktCount<10) //<10 // The voice is listened after image is rendered
            {
                vPktCount++;
            }
            else
            {
                if([aPlayer getStatus]!=eAudioRunning)
                {
                    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                    dispatch_async(aPlayerDispatchQueue, ^(void) {
                        @autoreleasepool
                        {
                            NSLog(@"aPlayer start play");
                            [aPlayer Play];
                        }
                    });
                }
            }
        }
    }
    
    
    
    NSLog(@"Leave ReadFrame");
}

#pragma mark - Recording Control
- (IBAction)VideoRecordPressed:(id)sender {
    
    if(bRecordStart==true)
    {
        bRecordStart = false;
        dispatch_async(aPlayerDispatchQueue, ^(void) {
            [aPlayer RecordingStop];
        });
    }
    else
    {
        // set recording format
        //vRecordingAudioFormat = kAudioFormatLinearPCM;// (Test ok)
        //vRecordingAudioFormat = kAudioFormatMPEG4AAC; //(need Test)
        bRecordStart = true;
        dispatch_async(aPlayerDispatchQueue, ^(void) {
#if 0
        [aPlayer RecordingSetAudioFormat:kAudioFormatLinearPCM];        
        [aPlayer RecordingStart:@"/Users/liaokuohsun/2.wav"];
#else
        [aPlayer RecordingSetAudioFormat:kAudioFormatMPEG4AAC];
        //[aPlayer RecordingStart:@"/Users/liaokuohsun/Audio2.mp4"];
        [aPlayer RecordingStart:@"/Users/miuki001/Audio2.mp4"];
        //[aPlayer RecordingStart:@"/Users/liaokuohsun/Audio2.m4a"];
#endif
        });
    }
}

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
        //NSLog(@"cell size %ld",sizeof(cell));
    }
    
    NSDictionary *URLDict = [URLListData objectAtIndex:indexPath.row];
    //NSLog(@"%@",[URLDict valueForKey:@"title"]);
    cell.textLabel.text = [URLDict valueForKey:@"title"];
    cell.accessoryType= UITableViewCellAccessoryDetailDisclosureButton;
    //cell.accessoryType= UITableViewCellAccessoryDisclosureIndicator;
    //cell.accessoryType= UITableViewCellAccessoryDetailButton;

    URLDict = nil;
    return cell;
}

//-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSDictionary *URLDict = [URLListData objectAtIndex:indexPath.row];
//    cell.textLabel.text = [URLDict valueForKey:@"title"];
//    URLDict = nil;
//}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Set the URL_TO_PLAY to the url user select
    NSDictionary *URLDict = [URLListData objectAtIndex:indexPath.row];
    pUserSelectedURL = nil;
    pUserSelectedURL = [URLDict valueForKey:@"url"];
//    URLNameToDisplay.text = [URLDict valueForKey:@"title"];
//    URLNameToDisplay.textAlignment = NSTextAlignmentCenter;
    
    URLDict = nil;
    
    // Start Play when user select the row
//    if([aPlayer getStatus]!=eAudioStop)
//        [self StopPlayAudio:_PlayAudioButton];
    [self PlayAudio:_PlayAudioButton];
    
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    
    NSDictionary *URLDict = [URLListData objectAtIndex:indexPath.row];
    NSString *pRaidoId = [URLDict valueForKey:@"id"];
    
    NSString *pMyDateString;
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS"];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    pMyDateString = [dateFormatter stringFromDate:now];
    
    // For different country, the program URL may be different
    // This is for taiwan only
    NSString *pUrl = [[NSString alloc]initWithFormat:@"http://hichannel.hinet.net/ajax/radio/program.do?id=%s&date=%s",
                      [pRaidoId UTF8String],
                      [pMyDateString UTF8String]];
    
    NSLog(@"accessoryButton press %d", indexPath.row);
    NSLog(@"pUrl %@", pUrl);
    
    //"http://hichannel.hinet.net/ajax/radio/program.do?id=205&date=2013-06-25"
    

    [GetRadioProgram GetRequest:pUrl];

    dateFormatter = nil;
    now = nil;
    pUrl = nil;
    pMyDateString = nil;
//        NSInteger row = indexPath.row;
//    nextControlView = [[NextControlView alloc] initWithNibName:@"NextControlView" bundle:nil];
//    nextControlView.Page=row;
//    [self.navigationController pushViewController:nextControlView animated:YES];
}

#pragma mark - volume_bar Slider
- (IBAction)VolumeBarPressed:(id)sender {
    [aPlayer SetVolume:VolumeBar.value];
}


#pragma mark - Play Timer PickView
// reference http://blog.csdn.net/zzfsuiye/article/details/6644566
// reference http://blog.sina.com.cn/s/blog_7119b1a40100vxwv.html
// 返回pickerview的组件数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 2;
}

// 返回每个组件上的行数
- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
    if(component==0)
    {
        return [PlayTimerMinuteOptions count];
    }
    else
    {
        return [PlayTimerSecondOptions count];
    }

}

// 设置每行显示的内容
- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if(component==0)
    {
        return [PlayTimerMinuteOptions objectAtIndex:row];
    }
    else
    {
        return [PlayTimerSecondOptions objectAtIndex:row];
    }
}

//使pickerview从底部出现
-(void) showPickerView {
    [UIView beginAnimations: @"Animation" context:nil];//设置动画
    [UIView setAnimationDuration:0.3];
    PlayTimePickerView.frame = CGRectMake(0,240, 320, 460);
    [UIView commitAnimations];
}

//使pickerview隐藏到屏幕底部
-(void) hidePickerView {
    [UIView beginAnimations:@"Animation"context:nil];
    [UIView setAnimationDuration:0.3];
    PlayTimePickerView.frame =CGRectMake(0,460, 320, 460);
    [UIView commitAnimations];
}

#if 0
//自定义pickerview使内容显示在每行的中间，默认显示在每行的左边
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,0.0f, [pickerView rowSizeForComponent:component].width, [pickerView rowSizeForComponent:component].height)];
    if (row ==0) {
        label.text =@"男";
    }else {
        label.text =@"女";
    }
    
    //[label setTextAlignment:UITextAlignmentCenter];
    [label setTextAlignment:NSTextAlignmentCenter];
    return label;
}
#endif

//当你选中pickerview的某行时会调用该函数。
- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSLog(@"You select component:%d row %d",component, row);
    if(component==0)
    {
        vPlayTimerMinute = [[PlayTimerMinuteOptions objectAtIndex:row] intValue];
    }
    else
    {
        vPlayTimerSecond = [[PlayTimerSecondOptions objectAtIndex:row] intValue];
    }
}

-(void)PlayTimerFired:(NSTimer *)timer {
    NSLog(@"PlayTimerFired");
    [self StopPlayAudio:nil];
    if(timer!=nil)
    {
        [timer invalidate];
        timer = nil;
    }
}


- (IBAction)PlayTimerButtonPressed:(id)sender {
    static int bPickerViewVisible = 0;
    
    if (PlayTimePickerView==nil) {
        PlayTimePickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0,460, 320, 460)];
        PlayTimePickerView.delegate = self;
        PlayTimePickerView.dataSource = self;
        PlayTimePickerView.showsSelectionIndicator = YES; //选中某行时会和其他行显示不同
        [self.view addSubview:PlayTimePickerView];
        //PlayTimePickerView= nil;
    }
    
    if(bPickerViewVisible==0)
    {
        bPickerViewVisible = 1;
        [self showPickerView];
    }
    else
    {
        // Choose Time and then set timer to stop play
        int vSeconds=0;
        vSeconds = vPlayTimerMinute*60 + vPlayTimerSecond;
        NSLog(@"Set Play Time to %d Seconds", vSeconds);
        [NSTimer scheduledTimerWithTimeInterval:vSeconds                                         target:self
                                       selector:@selector(PlayTimerFired:)
                                       userInfo:nil
                                        repeats:YES];
        bPickerViewVisible = 0;
        [self hidePickerView];

    }
}


#pragma mark - ad_banner_view
- (BOOL) allowActionToRun
{
    return YES;
}

#if 1
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
            pUserSelectedURL = [URLDict valueForKey:@"url"];
            pTestLog = [pTestLog stringByAppendingFormat:@"\ntest %@",pUserSelectedURL];
            [self PlayAudio:_PlayAudioButton];
        }
    }
}
#endif


@end
