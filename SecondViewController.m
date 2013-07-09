//
//  SecondViewController.m
//  FFmpegAudioPlayer
//
//  Created by albert on 13/6/23.
//  Copyright (c) 2013年 Liao KuoHsun. All rights reserved.
//

#import "SecondViewController.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

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
	// Do any additional setup after loading the view.
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)tappedCloseModal:(id)sender {
//    [self.navigationController popViewControllerAnimated:YES];
    [self dismissModalViewControllerAnimated: YES];
}
@end
