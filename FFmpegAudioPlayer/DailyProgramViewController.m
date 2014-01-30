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
    NSArray *pRadioProgramOn;
    NSDate *pDateSelected;
}
@end



@implementation DailyProgramViewController

@synthesize pRadioProgramUrlTemplate, pRadioProgramName;
@synthesize DailyProgramDayTable, pProgramDaySegCtrl;

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
    NSDate *today = [NSDate date];
    pDateSelected = today;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    // Parse daily program
    NSData* pJsonData;
    
    NSString *pMyDateString = [dateFormatter stringFromDate:today];
    NSString *pUrl = [[NSString alloc]initWithFormat:@"%@%@",pRadioProgramUrlTemplate,pMyDateString];
    pJsonData = [NSData dataWithContentsOfURL: [NSURL URLWithString:pUrl]];
                 
                 
    [self performSelectorOnMainThread:@selector(fetchedDataForHttpGet:) withObject:pJsonData waitUntilDone:YES];
    
    [super viewDidLoad];
    
    
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        self.automaticallyAdjustsScrollViewInsets=false;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
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
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 5, tableView.frame.size.width, 18)];
    [label setFont:[UIFont boldSystemFontOfSize:12]];
    [view setBackgroundColor:[UIColor whiteColor]];
    
    NSString *pDisplayText = [[NSString alloc] initWithString:pRadioProgramName] ;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"M/d"];
    pDisplayText = [pDisplayText stringByAppendingFormat:@"(%@)",[dateFormatter stringFromDate:pDateSelected]];
    pDisplayText = [pDisplayText stringByAppendingFormat:@"  播放列表"];

    [label setText:pDisplayText];
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
    
    // TODO: check if this program is active
    NSString *pOn = [[NSString alloc] initWithFormat:@"%@",[URLDict valueForKey:@"on"]] ;
    if( [pOn integerValue] == 1)
    {
        [cell.textLabel setTextColor:[UIColor redColor]];
    }
    else
    {
        [cell.textLabel setTextColor:[UIColor blackColor]];
    }
    return cell;
}

- (IBAction)pProgramDaySegSelected:(id)sender {
    NSTimeInterval secondsPerDay = 24*60*60;
    NSDate *tmpDate = [[NSDate alloc] initWithTimeIntervalSinceNow:
                       secondsPerDay*[sender selectedSegmentIndex]];
    pDateSelected = tmpDate;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    
    NSString *pMyDateString;
    pMyDateString = [dateFormatter stringFromDate:pDateSelected];
    
    // Parse daily program
    NSData* pJsonData;
    NSString *pUrl = [[NSString alloc]initWithFormat:@"%@%@",pRadioProgramUrlTemplate,pMyDateString];
    
    pJsonData = [NSData dataWithContentsOfURL: [NSURL URLWithString:pUrl]];
    [self performSelectorOnMainThread:@selector(fetchedDataForHttpGet:) withObject:pJsonData waitUntilDone:YES];
    
    [self.DailyProgramDayTable reloadData];
}
@end
