//
//  StopTimePickerViewController.h
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2014/2/1.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewController.h"
@interface StopTimePickerViewController : UIViewController
@property (strong, nonatomic) IBOutlet UIPickerView *PlayTimePickerView;
@property (nonatomic) ViewController *pViewController;
@end
