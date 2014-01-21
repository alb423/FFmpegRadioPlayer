//
//  SettingViewController.m
//  FFmpegRadioPlayer
//
//  Created by albert on 2014/1/21.
//  Copyright (c) 2014年 Liao KuoHsun. All rights reserved.
//

#import "SettingViewController.h"

@interface SettingViewController ()

@end

@implementation SettingViewController

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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(section==1)
        return 3;
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

//     CelluarNetworkCell
//     CacheSizeCell
//     RecoonectionCell
//     SleepTimeCell

    NSLog(@"init cell:%d",indexPath.row);
    UITableViewCell *cell ;
    NSString *CellIdentifier;
    
    switch(indexPath.row)
    {
        case 0:
             CellIdentifier = @"CelluarNetworkCell";
        break;
            
        case 1:
            CellIdentifier = @"CacheSizeCell";
            break;
            
        case 2:
            CellIdentifier = @"RecoonectionCell";
            break;

    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }


    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StunServerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    //[self.tableView reloadData];
}


@end
