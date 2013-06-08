//
//  YTBaseSettingsViewController.m
//  Backdoor
//
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTBaseSettingsViewController.h"
#import "YTAppDelegate.h"
#import "YTWebViewController.h"
#import "YTHelper.h"

@interface YTBaseSettingsViewController ()

@end

@implementation YTBaseSettingsViewController

- (void)openURL:(NSString*)url title:(NSString*)title;
{
    //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    YTWebViewController *controller = [[YTWebViewController alloc] initWithUrl:url title:title];
    [[YTAppDelegate current].navController pushViewController:controller animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITableViewStyle style = ([YTAppDelegate current].usesSplitView) ? UITableViewStylePlain : UITableViewStyleGrouped;
    
    self.tableView = [[UITableView alloc]initWithFrame:CGRectZero style:style];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = [UIColor whiteColor];
    //self.tableView.backgroundColor = [UIColor colorWithRed:0xed/255.0 green:0xec/255.0 blue:0xec/255.0 alpha:1];

    self.tableView.backgroundView = nil;
    [self.tableView reloadData];
    
    self.view = self.tableView;
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", nil) style:UIBarButtonItemStyleBordered target:nil action:nil];
    
    if ([YTAppDelegate current].usesSplitView) {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] animated:NO scrollPosition:UITableViewScrollPositionTop];
    }
    
}
- (void)viewWillDisappear:(BOOL)animated
{
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:animated];
}

#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableData count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableData[section] count];
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *item = self.tableData[indexPath.section][indexPath.row];
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    cell.textLabel.text =  item[1];
    cell.imageView.image = [YTHelper imageNamed:item[0]];
    cell.backgroundColor = [UIColor clearColor];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 45;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 1;
}

# pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    NSArray *item = self.tableData[indexPath.section][indexPath.row];
    NSString *method = item[2];
    SEL selector = NSSelectorFromString(method);
    
    if ([self respondsToSelector:selector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector];
#pragma clang diagnostic pop
    }
}

@end
