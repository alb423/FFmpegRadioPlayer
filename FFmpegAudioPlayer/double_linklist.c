//
//  double_linklist.c
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2013/12/6.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#include <stdio.h>
#include "double_linklist.h"

void MI_DlInit(tMI_DLIST *pList)
{
    if (pList)
    {
        pList->node.next = DLNODE_NIL;
        pList->node.prev = DLNODE_NIL;
        pList->count = 0;
    }
}


unsigned int MI_DlPushTail(tMI_DLIST *pList, tMI_DLNODE *pNode)
{
    if (pList && pNode)
    {
        if (pList->count >= MI_UTIL_MAXCOUNT)
        {
            return MI_UTIL_ERROR;
        }
        
        if (pList->node.next != DLNODE_NIL)
        {
            pNode->next = DLNODE_NIL;
            pNode->prev = pList->node.prev;
            pList->node.prev->next = pNode;
            pList->node.prev = pNode;
            pList->count++;
        }
        else
        {
            /** first element of the list **/
            pList->node.next = pNode;
            pList->node.prev = pNode;
            pNode->next = DLNODE_NIL;
            pNode->prev = DLNODE_NIL;
            pList->count = 1;
        }
        
        return pList->count;
    }
    
    return MI_UTIL_ERROR;
}

void MI_DlDelete(tMI_DLIST *pList, tMI_DLNODE *pNode)
{
    if (pList && pNode)
    {
        if (pList->count == 0)
        {
            return;
        }
        
        if (pNode->next == DLNODE_NIL)
        {
            /** Last in List **/
            pList->node.prev = pNode->prev;
        }
        else
        {
            pNode->next->prev = pNode->prev;
        }
        
        if (pNode->prev == DLNODE_NIL)
        {
            /** First in List **/
            pList->node.next = pNode->next;
        }
        else
        {
            pNode->prev->next = pNode->next;
        }
        
        pList->count--;
        
        pNode->prev = DLNODE_NIL;
        pNode->next = DLNODE_NIL;
    }
}

tMI_DLNODE *MI_DlPopHead(tMI_DLIST *pList)
{
    tMI_DLNODE *vpN = NULL;
    
    if (pList)
    {
        vpN = pList->node.next;
        if (vpN)
        {
            MI_DlDelete(pList, vpN);
        }
    }
    return (vpN);
}
