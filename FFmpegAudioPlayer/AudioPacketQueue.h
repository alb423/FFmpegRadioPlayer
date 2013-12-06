//
//  AudioPacketQueue.h
//  iFrameExtractor
//
//  Created by Liao KuoHsun on 13/4/19.
//
//

#import <Foundation/Foundation.h>
#include "libavformat/avformat.h"
#include "double_linklist.h"

#define AQ_PACKET_REC_SIZE 1024

#define AUDIO_QUEUE_IMPL_BY_OBJC 1
#define AUDIO_QUEUE_IMPL_BY_C    2

#define AUDIO_QUEUE_METHOD 1// AUDIO_QUEUE_IMPL_BY_C



@interface AudioPacketQueue : NSObject{
#if AUDIO_QUEUE_METHOD == AUDIO_QUEUE_IMPL_BY_OBJC
    NSMutableArray *pQueue;
#endif
    
    NSLock *pLock;

}
@property  (nonatomic)  NSInteger count;
@property  (nonatomic)  NSInteger size;
- (id) initQueue;
- (void) destroyQueue;
-(int) putAVPacket: (AVPacket *) pkt;
-(int) getAVPacket :(AVPacket *) pkt;
-(void)freeAVPacket:(AVPacket *) pkt;
@end
