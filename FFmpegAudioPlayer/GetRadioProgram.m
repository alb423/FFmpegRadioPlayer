//
//  GetRadioProgram.m
//  FFmpegAudioPlayer
//
//  Created by albert on 13/6/21.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import "GetRadioProgram.h"

#define BROADCAST_PROGRAM @"http://hichannel.hinet.net/ajax/radio/program.do?id=205&date=2013-06-25"

@implementation GetRadioProgram

#define JSON_ERR_NOPROGRAM_2 @"err_noprogram.json"

#define MAIN_QUEUE dispatch_get_main_queue()
#define GLOBAL_QUEUE dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

#pragma mark - Http Get
//- (IBAction)GetRequest:(id)sender {
+ (void) GetRequest {
    dispatch_async(GLOBAL_QUEUE, ^{
        @autoreleasepool {
            NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString:BROADCAST_PROGRAM]];
            [self performSelectorOnMainThread:@selector(fetchedDataForHttpGet:) withObject:data waitUntilDone:YES];
        }
    });
}

+ (void) GetRequest: (NSString *)URL {
    dispatch_async(GLOBAL_QUEUE, ^{
        @autoreleasepool {
            NSData* data = [NSData dataWithContentsOfURL: [NSURL URLWithString:URL]];
            [self performSelectorOnMainThread:@selector(fetchedDataForHttpGet:) withObject:data waitUntilDone:YES];
        }
    });
}

//- (void)fetchedDataForHttpGet:(NSData *)responseData {
+ (void)fetchedDataForHttpGet:(NSData *)responseData {
    //parse out the json data
    NSError* error;
    NSDictionary* jsonDictionary = [NSJSONSerialization JSONObjectWithData:responseData //1
                                                                   options:NSJSONReadingAllowFragments
                                                                     error:&error];
    
    //NSLog(@"json : %@", jsonDictionary);
    
    // 1) Set the label appropriately
    //_Response.text = [NSString stringWithFormat:@"Get Response \n %@",jsonDictionary];
    
    // 2) Retrive data in json and Set the label appropriately
    NSMutableString *pOutput = [[NSMutableString alloc]init];
    for(id key in [jsonDictionary allKeys])
    {
        [pOutput appendFormat:@"%@ : %@\n", key, [jsonDictionary objectForKey:key]];
    }
    //_ResponseSub.text = pOutput;
    
    //print out the data contents
    //NSLog(@"program: %@", [jsonDictionary objectForKey:@"program"]);
    NSArray *pPrograms = [jsonDictionary objectForKey:@"program"];
    NSDictionary *pProgram = [pPrograms objectAtIndex:0];
    
    NSLog(@"programDay: %@", [pProgram valueForKey:@"programDay"]);
    NSLog(@"programName: %@", [pProgram valueForKey:@"programName"]);
    NSLog(@"timeRange: %@", [pProgram valueForKey:@"timeRange"]);      
}

+ (NSArray *) parseJsonData:(NSData *)pJsonData {
    NSArray *pProgramArray;
    NSError* error;
    NSMutableDictionary* jsonDictionary = [NSJSONSerialization JSONObjectWithData:pJsonData //1
                                                                          options:NSJSONReadingAllowFragments
                                                                            error:&error];
    if(error!=nil)
    {
        NSLog(@"json transfer error %@", error);
        // TODO: make a fake jsonDictionary
        // and show error message on the form
        //parse out the json data
        NSError* error;
        
        NSString *pJsonDataPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:JSON_ERR_NOPROGRAM_2];
        NSData *pJsonData = [[NSFileManager defaultManager] contentsAtPath:pJsonDataPath];
        
        
        NSLog(@"%@", [[NSString alloc] initWithData:pJsonData encoding:NSUTF8StringEncoding]);
        jsonDictionary = [NSJSONSerialization JSONObjectWithData:pJsonData //1
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
        if(error!=nil)
        {
            NSLog(@"json transfer error %@", error);
            return nil;
            
        }
        //return;
    }
    
    
    //NSLog(@"json : %@",jsonDictionary);
    // 1) retrieve the URL list into NSArray
    // A simple test of URLListData
    pProgramArray = [jsonDictionary objectForKey:@"program"];
    if(pProgramArray==nil)
    {
        NSLog(@"URLListData load error!!");
        return nil;
    }
    return pProgramArray;
}

-(void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"didReceiveResponse");
    [httpPostResponse setLength:0];
}

-(void) connection:(NSURLConnection *) connection didReceiveData:(NSData *)data
{
    NSLog(@"didReceiveData");
    [httpPostResponse appendData:data];
}


-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"connectionDidFinishLoading");
    [self performSelectorOnMainThread:@selector(fetchedDataForHttpPost:) withObject:httpPostResponse waitUntilDone:YES];
}

@end
