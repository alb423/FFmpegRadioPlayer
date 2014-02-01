//
//  SettingsViewController.m
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2014/1/31.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import "SettingsViewController.h"
#import "StopTimePickerViewController.h"
#import "ChooseCacheSizeViewController.h"
@interface SettingsViewController ()
{
}
@end


@implementation SettingsViewController
{
    NSArray *PlayTimerSecondOptions;
    NSArray *PlayTimerMinuteOptions;
}

@synthesize pViewController;
@synthesize AutoReplaySwitch, CacheSizeCell, StopTimerCell;
@synthesize CacheSizeValueLabel, StopTimerValueLabel;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    if(pViewController.audioReplaySwitch==eReplaySwitch_On)
    {
        [AutoReplaySwitch setSelectedSegmentIndex:0];
    }
    else
    {
        [AutoReplaySwitch setSelectedSegmentIndex:1];
    }
    
    NSString *pTmp;
    if(pViewController.cacheSize==eCacheSize_Low)
    {
        pTmp = @"Low";
    }
    else if(pViewController.cacheSize==eCacheSize_Middle)
    {
        pTmp = @"Middle";
    }
    else
    {
        pTmp = @"High";
    }
    [CacheSizeValueLabel setText:pTmp];
    
    NSString* pTime = [[NSString alloc]initWithFormat:@"%dh %dm" ,
                       pViewController.stopTimerHours,
                       pViewController.stopTimerMinutes];

    [StopTimerValueLabel setText:pTime];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

// For static cell, below functions are unnecessary

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"didSelectRowAtIndexPath %d",indexPath.row);
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"accessoryButtonTappedForRowWithIndexPath %d",indexPath.row);
    if(indexPath.row==0)
    {
        ;
    }
    //[self performSegueWithIdentifier:@"ShowDailyProgram" sender:self.view];
}


- (IBAction)AutoReplaySwitchPressed:(id)sender {
    pViewController.audioReplaySwitch = [sender selectedSegmentIndex];
    NSLog(@"[sender selectedSegmentIndex]=%d",[sender selectedSegmentIndex]);
}

#pragma mark - segue control

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    NSLog(@"prepareForSegue");
    
    if([[segue identifier] isEqualToString:@"SetCacheSize"])
    {
        ChooseCacheSizeViewController *dstViewController = [segue destinationViewController];
        dstViewController.pViewController = self.pViewController;
        ;
    }
    else if([[segue identifier] isEqualToString:@"SetStopTimer"])
    {
        StopTimePickerViewController *dstViewController = [segue destinationViewController];
        dstViewController.pViewController = self.pViewController;
        ;
    }
    
}
@end
