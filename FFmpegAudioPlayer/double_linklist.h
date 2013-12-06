//
//  double_linklist.h
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2013/12/6.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#ifndef FFmpegRadioPlayer_double_linklist_h
#define FFmpegRadioPlayer_double_linklist_h

#define MI_NODEENTRY(ptr, type, member) \
((type *)((unsigned char *)(ptr)-(unsigned char *)(&((type *)0)->member)))

#define DLNODE_NIL ((tMI_DLNODE *)0)
#define MI_UTIL_MAXCOUNT 0xFFFFFFFE
#define MI_UTIL_ERROR 0xFFFFFFFF

typedef struct tMI_DLNODE
{
    struct tMI_DLNODE *next;
    struct tMI_DLNODE *prev;
} tMI_DLNODE;

typedef struct tMI_DLIST
{
    tMI_DLNODE node;
    unsigned int count;
} tMI_DLIST;

extern void MI_DlInit(tMI_DLIST *pList);
extern unsigned int MI_DlPushTail(tMI_DLIST *pList, tMI_DLNODE *pNode);
extern void MI_DlDelete(tMI_DLIST *pList, tMI_DLNODE *pNode);
extern tMI_DLNODE *MI_DlPopHead(tMI_DLIST *pList);

#endif
