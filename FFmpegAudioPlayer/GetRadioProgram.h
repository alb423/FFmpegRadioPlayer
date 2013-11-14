//
//  GetRadioProgram.h
//  FFmpegAudioPlayer
//
//  Created by albert on 13/6/21.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum  {
    eHttpGet = 1,
    eHttpPost = 2
}tHttpAction;

@interface GetRadioProgram : NSObject <UIApplicationDelegate, NSURLConnectionDelegate>
{
    tHttpAction HttpAction;
    NSMutableData *httpGetResponse;
    NSMutableData *httpPostResponse;
}

//- (IBAction)GetRequest:(id)sender;
+ (void) GetRequest;
+ (void) GetRequest: (NSString *)URL;
@end
