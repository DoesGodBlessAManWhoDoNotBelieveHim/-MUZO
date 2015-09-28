//
//  ViewController.h
//  仿MUZO
//
//  Created by wrt on 15/9/7.
//  Copyright (c) 2015年 wrtsoft. All rights reserved.
//

#import <UIKit/UIKit.h>


#import <MediaPlayer/MediaPlayer.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet MPVolumeView *myVolumeView;


@property (strong, nonatomic) IBOutlet UIButton *favoriteBtn;
@property (strong, nonatomic) IBOutlet UIButton *showListBtn;
@property (strong, nonatomic) IBOutlet UISlider *progressSlider;

@property (strong, nonatomic) IBOutlet UILabel *currentProgressLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *songFullTimeLabel;

@property (strong, nonatomic) IBOutlet UIButton *repeatTypeBtn;
@property (strong, nonatomic) IBOutlet UIButton *preSongBtn;
@property (strong, nonatomic) IBOutlet UIButton *playOrPauseSongBtn;
@property (strong, nonatomic) IBOutlet UIButton *nextSongBtn;

@end

