//
//  DailyProgramViewController.m
//  TabelDemo
//
//  Created by albert on 2013/11/19.
//  Copyright (c) 2013年 albert. All rights reserved.
//

#import "DailyProgramViewController.h"
#import "ViewController.h"
#import "GetRadioProgram.h"
#import "MyMacro.h"
#define JSON_ERR_NOPROGRAM @"err_noprogram.json"

@interface DailyProgramViewController ()
{
    NSArray *pRadioProgram;
}
@end



@implementation DailyProgramViewController

@synthesize pRadioProgramUrl, DailyProgramDayTable, pDailyProgramToday;

- (void)fetchedDataForHttpGet:(NSData *)responseData {
    NSError* error;
    NSMutableDictionary* jsonDictionary = [NSJSONSerialization JSONObjectWithData:responseData //1
                                                                          options:NSJSONReadingAllowFragments
                                                                            error:&error];
    if(error!=nil)
    {
        NSLog(@"json transfer error %@", error);
        // TODO: make a fake jsonDictionary
        // and show error message on the form
        //parse out the json data
        NSError* error;
        
        NSString *pJsonDataPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:JSON_ERR_NOPROGRAM];
        NSData *pJsonData = [[NSFileManager defaultManager] contentsAtPath:pJsonDataPath];
        
        
        NSLog(@"%@", [[NSString alloc] initWithData:pJsonData encoding:NSUTF8StringEncoding]);
        
        jsonDictionary = [NSJSONSerialization JSONObjectWithData:pJsonData //1
                                                         options:NSJSONReadingAllowFragments
                                                           error:&error];
        if(error!=nil)
        {
            NSLog(@"json transfer error %@", error);
            return;
            
        }
        //return;
    }

    //NSLog(@"json : %@",jsonDictionary);
    // 1) retrieve the URL list into NSArray
    // A simple test of URLListData
    pRadioProgram = [jsonDictionary objectForKey:@"program"];
    if(pRadioProgram==nil)
    {
        NSLog(@"URLListData load error!!");
        return;
    }

}

- (void)viewDidLoad
{
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [pDailyProgramToday setText:[dateFormatter stringFromDate:now]];
    
    NSData* pJsonData;
    pJsonData = [NSData dataWithContentsOfURL: [NSURL URLWithString:self.pRadioProgramUrl]];
    [self performSelectorOnMainThread:@selector(fetchedDataForHttpGet:) withObject:pJsonData waitUntilDone:YES];
 
    [super viewDidLoad];    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //self.navigationItem.backBarButtonItem
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        self.automaticallyAdjustsScrollViewInsets=false;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [pRadioProgram count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section//設定header
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 18)];
    /* Create custom view to display section header... */
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];

    /* Section header is in 0th index... */
    NSDate *now = [NSDate date];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"yyyy-MM-dd"];
    [dateFormatter setDateFormat:@"MM-dd"];
    // xx電台 09/22(六) 節目表
    [label setText:[dateFormatter stringFromDate:now]];
    [view addSubview:label];
    
    return view;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *URLDict = [pRadioProgram objectAtIndex:indexPath.row];
    
    NSString *OutputText = [[NSString alloc]initWithFormat:@"%@  %@",
                            [[URLDict valueForKey:@"timeRange"] substringToIndex:5],
                            [URLDict valueForKey:@"programName"]];
    cell.textLabel.text = OutputText;
    
    
    return cell;
}

@end
