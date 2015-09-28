//
//  PlayListViewController.m
//  WRTMusic
//
//  Created by wrt on 15/9/24.
//  Copyright (c) 2015年 wrtsoft. All rights reserved.
//

#import "PlayListViewController.h"


@interface PlayListViewController (){
    NSArray *dataSources;
}

@end

@implementation PlayListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"播放列表";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"searchdevice_back"] style:UIBarButtonItemStylePlain target:self action:@selector(dismiss)];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:15/255.0 green:15/255.0 blue:15/255.0 alpha:1];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:15/255.0 green:15/255.0 blue:15/255.0 alpha:1];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    
    dataSources = @[@"The Rain",@"Loving You",@"Her"];

}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return dataSources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyCell"];
    cell.textLabel.text = dataSources[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (_delegate) {
        [_delegate didSelectedIndex:indexPath.row];
    }
    [self dismiss];
}

- (void)dismiss{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
