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

#import "FSAudioController.h"

#import "PlayListViewController.h"


@interface ViewController ()<FSAudioControllerDelegate,PlayListViewControllerDelegate>{
    NSArray *allUrls;
//    NSInteger currentIndex;
    
    FSPlaylistItem *_playListItem;
    FSPlaylistItem *_selectedPlaylistItem;
    
    //FSAudioController *_audionController;
    
    FSStreamConfiguration *_configuration;
    
    NSURL *_lastPlaybackURL;
    FSSeekByteOffset _lastSeekByteOffset;
    
    BOOL _shouldStartPlaying;
}

@property (nonatomic, strong) FSAudioController *audionController;
@property (nonatomic, strong) FSStreamConfiguration *configuration;

@property (nonatomic, strong) FSPlaylistItem *playListItem;
@property (nonatomic, strong) FSPlaylistItem *selectedPlaylistItem;
@property (nonatomic, assign)   BOOL    paused;
@property (nonatomic, strong)   NSTimer *progressUpdateTimer;
//@property (nonatomic, assign)   float   volumeBeforeRamping;

@property (nonatomic, strong)   NSTimer *playbackSeekTimer;
@property (nonatomic, assign)   double  seekToPoint;
@property (nonatomic, strong)   NSURL   *stationUrl;

@property (nonatomic, assign)   BOOL    initialBuffering;
@property (nonatomic, assign)   UInt64  measurementCount;
@property (nonatomic, assign)   UInt64  audioStreamPacketCount;
@property (nonatomic, assign)   UInt64  bufferUnderrunCount;


- (void)updatePlaybackProgress;

- (void)seekToNewTime;

- (void)determineStationNameWithMetaData:(NSDictionary *)metaData;

- (void)doSeeking;

- (void)finalizeSeeking;


/**
 * Handles the notification upon entering background.
 *
 * @param notification The notification.
 */
- (void)applicationDidEnterBackgroundNotification:(NSNotification *)notification;
/**
 * Handles the notification upon entering foreground.
 *
 * @param notification The notification.
 */
- (void)applicationWillEnterForegroundNotification:(NSNotification *)notification;
/**
 * Handles remote control events.
 * @param receivedEvent The event received.
 */
- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;
@end



@implementation ViewController

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent
{
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        switch (receivedEvent.subtype) {
            case UIEventSubtypeRemoteControlPause: /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlPlay:  /* FALLTHROUGH */
            case UIEventSubtypeRemoteControlTogglePlayPause:{
                [self.audionController pause];
            }
                
                break;
            case UIEventSubtypeRemoteControlNextTrack:{
                [self.audionController playNextItem];
            }
                break;
            case UIEventSubtypeRemoteControlPreviousTrack:{
                [self.audionController playPreviousItem];
            }
                break;
            default:
                break;
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 注册通知
//    [NSNotificationCenter defaultCenter]addObserver:self selector:@selector() name:<#(NSString *)#> object:<#(id)#>
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    NSURL *rainMp3Url = [[NSBundle mainBundle]URLForResource:@"TheRain" withExtension:@"mp3"];
    NSURL *LYMp3Url = [[NSBundle mainBundle]URLForResource:@"LovingYou" withExtension:@"mp3"];
    NSURL *HERMp3Url = [[NSBundle mainBundle]URLForResource:@"Her" withExtension:@"mp3"];
    NSURL *netUrl = [NSURL URLWithString:@"http://cdn.y.baidu.com/yinyueren/data2/music/50943/ZmJsaGhkpKhkcauXpJqcdZSXlGtoaGlqkmpomZlnaGuWapWVmJydapaWZJmYZ5mZl2hjlmWXnW9oZJmWmGZobTE$/50943.mp3?xcode=cea73222a85ed113e8bacff2ed1ec1baf60b0af772fbc015"];
    allUrls = @[netUrl,rainMp3Url,LYMp3Url,HERMp3Url];
    
    self.myVolumeView.showsVolumeSlider = NO;
    self.preSongBtn.hidden = YES;
    
    self.stationUrl = nil;
#pragma mark - onStateChange
    __weak ViewController *weakSelf = self;
    self.audionController.onStateChange = ^(FSAudioStreamState state){
        switch (state) {
            case kFsAudioStreamRetrievingURL:{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                [SVProgressHUD showWithStatus:@"Retrieving URL..."];
                weakSelf.paused = NO;
                //weakSelf.playOrPauseSongBtn.hidden = YES;
                [weakSelf.playOrPauseSongBtn setImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
                
            }
                break;
            case kFsAudioStreamStopped:{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                if ([SVProgressHUD isVisible]) {
                    [SVProgressHUD dismiss];
                }
                weakSelf.paused = NO;
                [weakSelf.playOrPauseSongBtn setImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateNormal];
            }
                break;
            case kFsAudioStreamBuffering:{
                if (weakSelf.initialBuffering) {
                    weakSelf.initialBuffering = NO;
                }
                
                NSString *bufferingStatus = nil;
                if (weakSelf.configuration.usePrebufferSizeCalculationInSeconds) {
                    bufferingStatus = [NSString stringWithFormat:@"Buffering %f seconds...",weakSelf.audionController.activeStream.configuration.requiredPrebufferSizeInSeconds];
                }
                else{
                    bufferingStatus = [NSString stringWithFormat:@"Buffering %i bytes...",(weakSelf.audionController.activeStream.configuration ? weakSelf.configuration.requiredInitialPrebufferedByteCountForContinuousStream : weakSelf.configuration.requiredInitialPrebufferedByteCountForNonContinuousStream)];
                }
                [SVProgressHUD showWithStatus:bufferingStatus];
                
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                
                [weakSelf.playOrPauseSongBtn setImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
                weakSelf.paused = NO;
                
            }
                break;
            case kFsAudioStreamSeeking:{
                [SVProgressHUD showWithStatus:@"Seeking..."];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                weakSelf.paused = NO;
                
            }
                break;
            case kFsAudioStreamPlaying:{
                [weakSelf determineStationNameWithMetaData:nil];
                weakSelf.progressSlider.enabled = YES;
                [SVProgressHUD dismiss];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                if (!weakSelf.progressUpdateTimer) {
                    weakSelf.progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:weakSelf selector:@selector(updatePlaybackProgress) userInfo:nil repeats:YES];
                }
                
                [weakSelf toggleNextPreviousButtons];
                [weakSelf.playOrPauseSongBtn setImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
            }
                break;
            case kFsAudioStreamFailed:{
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                [weakSelf.playOrPauseSongBtn setImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateNormal];
                
            }
                break;
            case kFsAudioStreamPlaybackCompleted:{
                [weakSelf toggleNextPreviousButtons];
//                if ([weakSelf.audionController hasNextItem]) {
//                    //[weakSelf.audionController playNextItem];
//                }
//                else{
//                    [weakSelf.audionController playPreviousItem];
//                }
            }
                break;
            case kFsAudioStreamRetryingStarted:{
                //[weakSelf toggleNextPreviousButtons];
            }
                break;
            case kFsAudioStreamRetryingSucceeded:{
                
            }
                break;
            case kFsAudioStreamRetryingFailed:{
                [SVProgressHUD showErrorWithStatus:@"Failed to retry playback"];
            }
                break;
            default:
                break;
        }
    };
    #pragma mark - onFailure
    self.audionController.onFailure=^(FSAudioStreamError error, NSString *errorDescription){
        NSString *errorCategory;
        switch (error) {
            case kFsAudioStreamErrorOpen:
                errorCategory = @"Cannot open the audio stream:";
                break;
            case kFsAudioStreamErrorStreamParse:
                errorCategory = @"Cannot read the audio stream:";
                break;
            case kFsAudioStreamErrorNetwork:
                errorCategory = @"Network failed: cannot play the audio stream:";
                break;
            case kFsAudioStreamErrorUnsupportedFormat:
                errorCategory = @"Unsupported format:";
                break;
            case kFsAudioStreamErrorStreamBouncing:
                errorCategory = @"Network failed: cannot get enough data to play:";
                break;
                
            default:
                errorCategory = @"Unknown error occurred:";
                break;
        }
        
        NSString *formattedError = [NSString stringWithFormat:@"%@ %@",errorCategory,errorDescription];
        
        [SVProgressHUD showErrorWithStatus:formattedError];
        
    };
    
    self.audionController.onMetaDataAvailable=^(NSDictionary *metaData){
        
        [weakSelf determineStationNameWithMetaData:metaData];
        
        NSMutableDictionary *songInfo = [NSMutableDictionary dictionary];
        
        if ([metaData objectForKey:@"MPMediaItemPropertyTitle"]) {
            [songInfo setObject:MPMediaItemPropertyTitle forKey:metaData[@"MPMediaItemPropertyTitle"]];
        }
        else if (metaData[@"StreamTitle"]){
            songInfo[MPMediaItemPropertyTitle]=metaData[@"StreamTitle"];
        }
        
        if (metaData[@"MPMediaItemPropertyArtist"]) {
            songInfo[MPMediaItemPropertyArtist] = metaData[@"MPMediaItemPropertyArtist"];
        }
        
        [[MPNowPlayingInfoCenter defaultCenter]setNowPlayingInfo:songInfo];
        
        NSMutableString *streamInfo = [[NSMutableString alloc]init];
        if (metaData[@"MPMediaItemPropertyArtist"] && metaData[@"MPMediaItemPropertyTitle"]) {
            [streamInfo appendString:metaData[@"MPMediaItemPropertyArtist"]];
            [streamInfo appendString:@"-"];
            [streamInfo appendString:metaData[@"MPMediaItemPropertyTitle"]];
        }
        else if (metaData[@"StreamTitle"]){
            [streamInfo appendString:metaData[@"StreamTitle"]];
        }
        
        weakSelf.title = streamInfo;
    };
    
    // 这里可以先判断是否进入自动播放
    [self.audionController play];
    
    _progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updatePlaybackProgress) userInfo:nil repeats:YES];
    
}

- (FSAudioController *)audionController{
    if (!_audionController) {
        _audionController = [[FSAudioController alloc] init];
        
        FSPlaylistItem *item1 = [[FSPlaylistItem alloc]init];
        item1.url = allUrls[0];
        FSPlaylistItem *item2 = [[FSPlaylistItem alloc]init];
        item2.url = allUrls[1];
        FSPlaylistItem *item3 = [[FSPlaylistItem alloc]init];
        item3.url = allUrls[2];
        //[_audionController playFromPlaylist:@[item1,item2]];
        [_audionController addItem:item1];
        [_audionController addItem:item2];
        [_audionController addItem:item3];
        _audionController.delegate = self;
    }
    return _audionController;
}

- (void)determineStationNameWithMetaData:(NSDictionary *)metaData
{
    if (metaData[@"IcecastStationName"] && [metaData[@"IcecastStationName"] length] > 0) {
        self.navigationController.navigationBar.topItem.title = metaData[@"IcecastStationName"];
    } else {
        FSPlaylistItem *playlistItem = self.audionController.currentPlaylistItem;
        NSString *title = playlistItem.title;
        
        if ([playlistItem.title length] > 0) {
            self.navigationController.navigationBar.topItem.title = title;
        } else {
            /* The last resort - use the URL as the title, if available */
            if (metaData[@"StreamUrl"] && [metaData[@"StreamUrl"] length] > 0) {
                self.navigationController.navigationBar.topItem.title = metaData[@"StreamUrl"];
            }
        }
    }
}

-(void)toggleNextPreviousButtons
{
    if([self.audionController hasNextItem] || [self.audionController hasPreviousItem])
    {
        self.nextSongBtn.hidden = NO;
        self.preSongBtn.hidden = NO;
        self.nextSongBtn.enabled = [self.audionController hasNextItem];
        self.preSongBtn.enabled = [self.audionController hasPreviousItem];
    }
    else
    {
        self.nextSongBtn.hidden = YES;
        self.preSongBtn.hidden = YES;
    }
}

- (FSPlaylistItem *)selectedPlaylistItem
{
    return _selectedPlaylistItem;
}

- (void)setSelectedPlaylistItem:(FSPlaylistItem *)selectedPlaylistItem
{
    _selectedPlaylistItem = selectedPlaylistItem;
    
    self.navigationItem.title = self.selectedPlaylistItem.title;
    
    if (self.selectedPlaylistItem.url) {
        self.audionController.url =  self.selectedPlaylistItem.url;
    } else if (self.selectedPlaylistItem.originatingUrl) {
        self.audionController.url = self.selectedPlaylistItem.originatingUrl;
    }
}

- (void)doSeeking
{
    FSStreamPosition pos = {0};
    pos.position = _seekToPoint;
    
    [self.audionController.activeStream seekToPosition:pos];
}

- (void)updatePlaybackProgress
{
    if (self.audionController.activeStream.continuous) {
        self.progressSlider.enabled = NO;
        self.progressView.progress = 0;
        self.currentProgressLabel.text = @"";
        self.songFullTimeLabel.text = @"";
    } else {
        self.progressSlider.enabled = YES;
        
        FSStreamPosition cur = self.audionController.activeStream.currentTimePlayed;
        FSStreamPosition end = self.audionController.activeStream.duration;
        
        self.progressView.progress = cur.position;
        self.progressSlider.value = cur.position;
        
        self.currentProgressLabel.text = [NSString stringWithFormat:@"%i:%02i",cur.minute, cur.second];
        self.songFullTimeLabel.text = [NSString stringWithFormat:@"%i:%02i",end.minute, end.second];
    }
    
    //self.bufferingIndicator.hidden = NO;
    //self.prebufferStatus.hidden = YES;
    
    if (self.audionController.activeStream.contentLength > 0) {
        // A non-continuous stream, show the buffering progress within the whole file
        FSSeekByteOffset currentOffset = self.audionController.activeStream.currentSeekByteOffset;
        
        UInt64 totalBufferedData = currentOffset.start + self.audionController.activeStream.prebufferedByteCount;
        
        float bufferedDataFromTotal = (float)totalBufferedData / self.audionController.activeStream.contentLength;
        
        //self.bufferingIndicator.progress = (float)currentOffset.start / self.audioController.activeStream.contentLength;
        
        // Use the status to show how much data we have in the buffers
        //self.prebufferStatus.frame = CGRectMake(self.bufferingIndicator.frame.origin.x,
//                                                self.bufferingIndicator.frame.origin.y,
//                                                CGRectGetWidth(self.bufferingIndicator.frame) * bufferedDataFromTotal,
//                                                5);
//        self.prebufferStatus.hidden = NO;
    } else {
        // A continuous stream, use the buffering indicator to show progress
        // among the filled prebuffer
//        self.bufferingIndicator.progress = (float)self.audioController.activeStream.prebufferedByteCount / _maxPrebufferedByteCount;
    }
}


#pragma mark - IBAction
- (IBAction)_setSongFavorite:(UIButton *)sender {
}

- (IBAction)seekoffset:(UISlider *)sender {
    _seekToPoint = self.progressSlider.value;
    [_progressUpdateTimer invalidate];
    _progressUpdateTimer = nil;
    
    [_playbackSeekTimer invalidate];
    _playbackSeekTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(seekToNewTime) userInfo:nil repeats:NO];
}

- (void)seekToNewTime{
    self.progressSlider.enabled = NO;
    
    [self doSeeking];
}

- (IBAction)_showSongsList:(UIButton *)sender {
    [self performSegueWithIdentifier:@"showSongList" sender:self];
}
- (IBAction)_setRepeatType:(UIButton *)sender {
}
- (IBAction)_preSongAction:(id)sender {
    [self.audionController playPreviousItem];
    }
- (IBAction)_playOrPauseAction:(id)sender {
    if (self.audionController.isPlaying) {
        [self.audionController pause];
        [self.playOrPauseSongBtn setImage:[UIImage imageNamed:@"playBtn"] forState:UIControlStateNormal];
        self.paused = YES;
    }
    else{
        [self.audionController pause];
        [self.playOrPauseSongBtn setImage:[UIImage imageNamed:@"pauseBtn"] forState:UIControlStateNormal];
    }
}
- (IBAction)_nextSongAction:(id)sender {
    [self.audionController playNextItem];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)audioController:(FSAudioController *)audioController allowPreloadingForStream:(FSAudioStream *)stream
{
    // We could do some fine-grained control here depending on the connectivity status, for example.
    // Allow all preloads for now.
    return YES;
}

- (void)didSelectedIndex:(NSInteger)index{
    if ([self.audionController.currentPlaylistItem.url isEqual:allUrls[index]]) {
        
    }
    else{
        if (self.audionController.isPlaying) {
            [self.audionController pause];
        }
        
        [self.audionController playItemAtIndex:index];
    }
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"showSongList"]) {
        UINavigationController *nVC = [segue destinationViewController];
        PlayListViewController *plVC = (PlayListViewController *)nVC.topViewController;
        plVC.delegate = self;
    }
}

@end
