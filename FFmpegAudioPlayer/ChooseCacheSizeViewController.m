//
//  ChooseCacheSizeViewController.m
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2014/2/1.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import "ChooseCacheSizeViewController.h"

@interface ChooseCacheSizeViewController ()

@end

@implementation ChooseCacheSizeViewController
@synthesize pViewController;
@synthesize CacheSizeSeg;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [CacheSizeSeg setSelectedSegmentIndex:self.pViewController.cacheSize];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)CacheSizeSegPressed:(id)sender {
    self.pViewController.cacheSize = [sender selectedSegmentIndex];
    
    if(self.pViewController.cacheSize==eCacheSize_Low)
        [pViewController setAudioBufferThreshold:eAudioThreshold_Low];
    else if(self.pViewController.cacheSize==eCacheSize_Low)
        [pViewController setAudioBufferThreshold:eAudioThreshold_Middle];
    else
        [pViewController setAudioBufferThreshold:eAudioThreshold_High];
}
@end
