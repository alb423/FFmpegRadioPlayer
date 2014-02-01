//
//  SettingsViewController.h
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2014/1/31.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
@interface SettingsViewController : UITableViewController

@property (nonatomic) ViewController *pViewController;
@property (strong, nonatomic) IBOutlet UISegmentedControl *AutoReplaySwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *CacheSizeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *StopTimerCell;


@property (strong, nonatomic) IBOutlet UILabel *CacheSizeValueLabel;
@property (strong, nonatomic) IBOutlet UILabel *StopTimerValueLabel;


- (IBAction)AutoReplaySwitchPressed:(id)sender;

@end
