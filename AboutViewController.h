//
//  AboutViewController.h
//  FFmpegRadioPlayer
//
//  Created by albert on 2014/1/21.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
@interface AboutViewController : UIViewController<MFMailComposeViewControllerDelegate>

- (IBAction)EmailSuggestionPressed:(id)sender;

@end
