//
//  PlayListViewController.h
//  WRTMusic
//
//  Created by wrt on 15/9/24.
//  Copyright (c) 2015年 wrtsoft. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PlayListViewControllerDelegate <NSObject>

- (void)didSelectedIndex:(NSInteger)index;

@end

@interface PlayListViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, assign) id<PlayListViewControllerDelegate> delegate;

@property (strong, nonatomic) IBOutlet UITableView *myTableView;
@end
