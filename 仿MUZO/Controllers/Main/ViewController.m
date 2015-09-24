//
//  ViewController.m
//  仿MUZO
//
//  Created by wrt on 15/9/7.
//  Copyright (c) 2015年 wrtsoft. All rights reserved.
//

#import "ViewController.h"

#import "FSAudioStream.h"

#import "FSPlaylistItem.h"

@interface ViewController (){
    NSArray *allUrls;
    NSInteger currentIndex;
    
    FSPlaylistItem *playListItem;
}

@property (strong, nonatomic) FSAudioStream *audioStream;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

}


#pragma mark - IBAction
- (IBAction)_setSongFavorite:(UIButton *)sender {
}
- (IBAction)_showSongsList:(UIButton *)sender {
}
- (IBAction)_setRepeatType:(UIButton *)sender {
}
- (IBAction)_preSongAction:(id)sender {
    }
- (IBAction)_playOrPauseAction:(id)sender {
    }
- (IBAction)_nextSongAction:(id)sender {
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
