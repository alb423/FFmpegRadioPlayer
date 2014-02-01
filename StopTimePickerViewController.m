//
//  StopTimePickerViewController.m
//  FFmpegRadioPlayer
//
//  Created by Liao KuoHsun on 2014/2/1.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import "StopTimePickerViewController.h"

@interface StopTimePickerViewController ()

@end

@implementation StopTimePickerViewController
{
    NSArray *PlayTimerHoursOptions;
    NSArray *PlayTimerMinutesOptions;
}

@synthesize PlayTimePickerView;
@synthesize pViewController;

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
    
    // init PlayTimer options
    PlayTimerMinutesOptions = [[NSArray alloc]initWithObjects:@"0",@"5",@"10",@"15",@"20",@"25",@"30",@"35",@"40",@"45",@"50",@"55",@"60",nil];
    PlayTimerHoursOptions = [[NSArray alloc]initWithObjects:@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12",nil];
    
    PlayTimePickerView.delegate = self;
    PlayTimePickerView.dataSource = self;
    PlayTimePickerView.showsSelectionIndicator = YES; //选中某行时会和其他行显示不同

    NSUInteger vH = [PlayTimerHoursOptions indexOfObject:[NSString stringWithFormat: @"%d", pViewController.stopTimerHours]];
    NSUInteger vT = [PlayTimerMinutesOptions indexOfObject:[NSString stringWithFormat: @"%d", pViewController.stopTimerMinutes]];
    
    [PlayTimePickerView selectRow:vH inComponent:0 animated:NO];
    [PlayTimePickerView selectRow:vT inComponent:1 animated:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Play Timer PickView
// reference http://blog.csdn.net/zzfsuiye/article/details/6644566
// reference http://blog.sina.com.cn/s/blog_7119b1a40100vxwv.html
// 返回pickerview的组件数
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
    return 2;
}

// 返回每个组件上的行数
- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component
{
    if(component==0)
    {
        return [PlayTimerHoursOptions count];
    }
    else
    {
        return [PlayTimerMinutesOptions count];
    }
    
}

// 设置每行显示的内容
- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if(component==0)
    {
        return [PlayTimerHoursOptions objectAtIndex:row];
    }
    else
    {
        return [PlayTimerMinutesOptions objectAtIndex:row];
    }
}

#if 0
//自定义pickerview使内容显示在每行的中间，默认显示在每行的左边
- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,0.0f, [pickerView rowSizeForComponent:component].width, [pickerView rowSizeForComponent:component].height)];
    if (row ==0) {
        label.text =@"男";
    }else {
        label.text =@"女";
    }
    
    //[label setTextAlignment:UITextAlignmentCenter];
    [label setTextAlignment:NSTextAlignmentCenter];
    return label;
}
#endif

//当你选中pickerview的某行时会调用该函数。
- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSLog(@"You select component:%d row %d",component, row);
    if(component==0)
    {
        pViewController.stopTimerHours = [[PlayTimerHoursOptions objectAtIndex:row] intValue];
    }
    else
    {
        pViewController.stopTimerMinutes = [[PlayTimerMinutesOptions objectAtIndex:row] intValue];
    }
}

@end
