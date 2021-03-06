//
//  DailyProgramViewController.h
//  TabelDemo
//
//  Created by albert on 2013/11/19.
//  Copyright (c) 2013年 albert. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DailyProgramViewController : UIViewController <UITableViewDelegate>
{
    ;
}


@property (weak, nonatomic) IBOutlet UITableView *DailyProgramDayTable;
@property (strong, nonatomic) IBOutlet UISegmentedControl *pProgramDaySegCtrl;

- (IBAction)pProgramDaySegSelected:(id)sender;

@property (strong) NSString *pRadioProgramUrlTemplate;
@property (strong) NSString *pRadioProgramName;
@end
