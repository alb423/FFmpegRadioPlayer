//
//  AudioPacketQueue.m
//  a queue to store AVPacket from ffmpeg
//
//  Created by Liao KuoHsun on 13/4/19.
//
//

#import "AudioPacketQueue.h"

@implementation AudioPacketQueue

@synthesize count;
@synthesize size;

#if AUDIO_QUEUE_METHOD == AUDIO_QUEUE_IMPL_BY_C


tMI_DLIST vxAQList;
int initMemRecFlag = 0;

typedef struct pktrec
{
    tMI_DLNODE Node;
    void *p;
    int idx;
} pktrec;


- (id) initQueue
{
    self = [self init];
    if(self != nil)
    {
        pLock = [[NSLock alloc]init];
        count = 0;
        size = 0;
        
        MI_DlInit(&vxAQList);
        
        initMemRecFlag = 1;
    }
    return self;
}


- (void) destroyQueue {
    
    tMI_DLNODE * vpNode = NULL;
    pktrec *vpPR=NULL;
    
    [pLock lock];
    vpNode = MI_DlPopHead(&vxAQList);
    
    while (vpNode)
    {
        vpPR = MI_NODEENTRY(vpNode, pktrec, Node);
        
        if (initMemRecFlag)
        {
            AVPacket *vp = vpPR->p;
            vp -= sizeof(pktrec);
            if(vp)
              av_free_packet(vp);
        }
        else
        {
            free(vpPR->p);
        }
        
        vpPR->p = NULL;
        
        vpNode = MI_DlPopHead(&vxAQList);
    }
    
    count = 0;
    size = 0;
    [pLock unlock];
    
    NSLog(@"Release Audio Packet Queue");
    if(pLock) pLock = nil;
    
}

-(int) putAVPacket: (AVPacket *) pPacket{
    
    NSLog(@"putAVPacket %d", count);
    // memory leakage is related to pPacket
    if ((av_dup_packet(pPacket)) < 0) {
        NSLog(@"Error duplicating packet");
    }
    
    [pLock lock];
    
    typedef struct pktrec
    {
        tMI_DLNODE Node;
        void *p;
        int idx;
    } pktrec;
    
    pktrec * newrec = (pktrec *) malloc(sizeof(pktrec));
    
    newrec->p = (void *)pPacket;
    size += pPacket->size;
    
    MI_DlPushTail(&vxAQList, &newrec->Node);

    count ++;
    [pLock unlock];
    
    return 1;
}

-(int ) getAVPacket :(AVPacket *) pPacket{
    
    NSLog(@"getAVPacket %d", count);
    [pLock  lock];
    
    tMI_DLNODE * vpNode = NULL;
    pktrec * vpPR = NULL;
    
    vpNode = MI_DlPopHead(&vxAQList);
    
    vpPR = MI_NODEENTRY(vpNode, pktrec, Node);
    pPacket = (AVPacket *) vpPR->p;
    free(vpPR);

    if(vpNode)
    {
        count--;
        [pLock unlock];
        return 1;
    }
    else
    {
        [pLock unlock];
        return 0;
    }
}

-(void)freeAVPacket:(AVPacket *) pPacket{
    [pLock  lock];
    av_free_packet(pPacket);
    [pLock unlock];
}

#else
- (id) initQueue
{
    self = [self init];

    if(pQueue==nil)
        pQueue = [[NSMutableArray alloc] init];
    
    if(pLock==nil)
        pLock = [[NSLock alloc]init];
    
    count = 0;
    size = 0;
    return self;
}

// Useless in ARC mode
- (void) destroyQueue {
    AVPacket vxPacket;
    NSMutableData *packetData = nil;
    
    [pLock lock];
    NSLog(@"Free AudioPacketQueue Count=%d",[pQueue count]);
    while ([pQueue count]>0) {
        packetData = [pQueue objectAtIndex:0];
        if(packetData!= nil)
        {
            [packetData getBytes:&vxPacket];
            av_free_packet(&vxPacket);
            packetData = nil;
            [pQueue removeObjectAtIndex: 0];
            count--;
        }
    }
    //[pQueue removeAllObjects];
    count = 0;
    size = 0;
    NSLog(@"Release Audio Packet Queue");
    
    if(pQueue) pQueue = nil;
    
    [pLock unlock];
    if(pLock) pLock = nil;

}

-(int) putAVPacket: (AVPacket *) pPacket{

    // memory leakage is related to pPacket
//    if ((av_dup_packet(pPacket)) < 0) {
//        NSLog(@"Error duplicating packet");
//    }
//    
    [pLock lock];
    
    //NSLog(@"putAVPacket %d", [pQueue count]);
    NSMutableData *pTmpData = [[NSMutableData alloc] initWithBytes:pPacket length:sizeof(*pPacket)];
    [pQueue addObject: pTmpData];
    size += pPacket->size;
    pTmpData = nil;
    count= count + 1;
    [pLock unlock];
    return 1;
}

-(int ) getAVPacket :(AVPacket *) pPacket{
    NSMutableData *packetData = nil;
    
    // Do we have any items?
    [pLock  lock];
    //if ([pQueue count]>0) {
    if (count>0) {
        packetData = [pQueue objectAtIndex:0];
        if(packetData!= nil)
        {
//            int vCount = [pQueue count];
//            if(vCount<10)
//                NSLog(@"getAVPacket %d", vCount);
            [packetData getBytes:pPacket];
            packetData = nil;
            [pQueue removeObjectAtIndex: 0];
            if(pPacket)
                size = size - pPacket->size;
            count--;
        }
        [pLock unlock];
        return 1;
    }
    else
    {
        [pLock unlock];
        return 0;
    }

    return 0;
}

-(void)freeAVPacket:(AVPacket *) pPacket{
    [pLock  lock];
    av_free_packet(pPacket);
    [pLock unlock];
}
#endif


@end
