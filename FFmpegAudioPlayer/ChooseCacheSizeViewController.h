//
//  ChooseCacheSizeViewController.h
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2014/2/1.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
@interface ChooseCacheSizeViewController : UIViewController
@property (nonatomic) ViewController *pViewController;

@property (strong, nonatomic) IBOutlet UISegmentedControl *CacheSizeSeg;
- (IBAction)CacheSizeSegPressed:(id)sender;

@end
