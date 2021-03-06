//
//  DNTableViewController.m
//  DNTagView
//
//  Created by dawnnnnn on 2016/10/14.
//  Copyright © 2016年 dawnnnnn. All rights reserved.
//

#import "DNTableViewController.h"
#import "DNMultiLineEditViewController.h"
#import "DNMultiLineShowViewController.h"

@interface DNTableViewController ()

@property (nonatomic, strong) NSArray *dataArray;

@end

@implementation DNTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Tags Demo";
    self.dataArray = @[@"Multiple lines Show", @"Multiple lines Edit"].copy;
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"tagIdentifier"];
    self.tableView.rowHeight = 44.f;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tagIdentifier" forIndexPath:indexPath];
    cell.textLabel.text = self.dataArray[indexPath.row];
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0: {
            DNMultiLineShowViewController *controller = [DNMultiLineShowViewController new];
            [self.navigationController pushViewController:controller animated:YES];
        } break;
        case 1: {
            DNMultiLineEditViewController *controller = [DNMultiLineEditViewController new];
            [self.navigationController pushViewController:controller animated:YES];
        } break;
        default:
            break;
    }
}


@end
