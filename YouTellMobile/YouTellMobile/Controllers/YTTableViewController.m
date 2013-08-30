//
//  YTTableViewController.m
//  Backdoor
//
//  Created by Lin Xu on 8/30/13.
//  Copyright (c) 2013 4WT. All rights reserved.
//

#import "YTTableViewController.h"
#import "YTHelper.h"

@interface YTTableViewController ()

@end

@implementation YTTableViewController

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
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0,0,self.view.frame.size.width,self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionHeaderHeight = 0;
    
    self.searchBar = [UISearchBar new];
    [self.searchBar sizeToFit];
    self.searchBar.delegate = self;
    self.searchBar.backgroundImage = [YTHelper imageNamed:@"navbar3"];
    self.tableView.tableHeaderView = self.searchBar;
    self.tableView.tableFooterView = [UIView new];
    self.tableView.backgroundColor = [UIColor clearColor];

    self.view.backgroundColor = [UIColor colorWithRed:237/255.0 green:237/255.0 blue:237/255.0 alpha:1];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:
                    UIActivityIndicatorViewStyleWhiteLarge];
    
    self.spinner.color = [UIColor grayColor];

    [self.view addSubview:self.tableView];
    [self.view addSubview:self.spinner];
    [self setupNavBar];
}

- (void)setupNavBar
{
    self.navigationItem.backBarButtonItem = nil;
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonWasClicked)];
}

- (void)cancelButtonWasClicked
{   
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showSpinner
{
    self.spinner.center = self.view.center;
    [self.spinner startAnimating];
}

- (void) hideSpinner
{
    [self.spinner stopAnimating];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}



@end
