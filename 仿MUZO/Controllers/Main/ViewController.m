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



@interface ViewController ()<FSAudioControllerDelegate>{
//    NSArray *allUrls;
//    NSInteger currentIndex;
    
    FSPlaylistItem *_playListItem;
    FSPlaylistItem *_selectedPlaylistItem;
    
    FSAudioController *_audionController;
    
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



- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    //self.nextSongBtn.hidden = YES;
    self.preSongBtn.hidden = YES;
    
    self.stationUrl = nil;
    
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
            }
                break;
            case kFsAudioStreamRetryingStarted:{
                
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
    
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    _progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updatePlaybackProgress) userInfo:nil repeats:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    FSPlaylistItem *playListItem = [[FSPlaylistItem alloc]init];
//    playListItem.url = ((AppDelegate *)[UIApplication sharedApplication].delegate).localUrl;
//    playListItem.originatingUrl = ((AppDelegate *)[UIApplication sharedApplication].delegate).localUrl;
//    //self.audionController.activeStream.strictContentTypeChecking = NO;
//    [self setPlayListItem:playListItem];
//    [self setSelectedPlaylistItem:playListItem];
}

- (FSAudioController *)audioController
{
    if (!_audionController) {
        _audionController = [[FSAudioController alloc] init];
        NSURL *rainMp3Url = [[NSBundle mainBundle]URLForResource:@"TheRain" withExtension:@"mp3"];
        NSURL *LYMp3Url = [[NSBundle mainBundle]URLForResource:@"LovingYou" withExtension:@"mp3"];
        FSPlaylistItem *item1 = [[FSPlaylistItem alloc]init];
        item1.url = rainMp3Url;
        FSPlaylistItem *item2 = [[FSPlaylistItem alloc]init];
        item2.url = LYMp3Url;
        [_audionController playFromPlaylist:@[item1,item2]];
        _audionController.delegate = self;
    }
    return _audionController;
}

- (void)determineStationNameWithMetaData:(NSDictionary *)metaData
{
    if (metaData[@"IcecastStationName"] && [metaData[@"IcecastStationName"] length] > 0) {
        self.navigationController.navigationBar.topItem.title = metaData[@"IcecastStationName"];
    } else {
        FSPlaylistItem *playlistItem = self.audioController.currentPlaylistItem;
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
    if([self.audioController hasNextItem] || [self.audioController hasPreviousItem])
    {
        self.nextSongBtn.hidden = NO;
        self.preSongBtn.hidden = NO;
        self.nextSongBtn.enabled = [self.audioController hasNextItem];
        self.preSongBtn.enabled = [self.audioController hasPreviousItem];
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
        self.audioController.url =  self.selectedPlaylistItem.url;
    } else if (self.selectedPlaylistItem.originatingUrl) {
        self.audioController.url = self.selectedPlaylistItem.originatingUrl;
    }
}

- (void)doSeeking
{
    FSStreamPosition pos = {0};
    pos.position = _seekToPoint;
    
    [self.audioController.activeStream seekToPosition:pos];
}

- (void)updatePlaybackProgress
{
    if (self.audioController.activeStream.continuous) {
        //self.progressSlider.enabled = NO;
        self.progressView.progress = 0;
        //self.currentPlaybackTime.text = @"";
    } else {
        //self.progressSlider.enabled = YES;
        
        FSStreamPosition cur = self.audioController.activeStream.currentTimePlayed;
        FSStreamPosition end = self.audioController.activeStream.duration;
        
        self.progressView.progress = cur.position;
        
        //self.currentPlaybackTime.text = [NSString stringWithFormat:@"%i:%02i / %i:%02i",
//                                         cur.minute, cur.second,
//                                         end.minute, end.second];
    }
    
    //self.bufferingIndicator.hidden = NO;
    //self.prebufferStatus.hidden = YES;
    
    if (self.audioController.activeStream.contentLength > 0) {
        // A non-continuous stream, show the buffering progress within the whole file
        FSSeekByteOffset currentOffset = self.audioController.activeStream.currentSeekByteOffset;
        
        UInt64 totalBufferedData = currentOffset.start + self.audioController.activeStream.prebufferedByteCount;
        
        float bufferedDataFromTotal = (float)totalBufferedData / self.audioController.activeStream.contentLength;
        
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
- (IBAction)_showSongsList:(UIButton *)sender {
}
- (IBAction)_setRepeatType:(UIButton *)sender {
}
- (IBAction)_preSongAction:(id)sender {
    [self.audionController playPreviousItem];
    }
- (IBAction)_playOrPauseAction:(id)sender {
    if (self.paused) {
        [self.audionController pause];
        self.paused = NO;
    }
    else{
        [self.audionController play];
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

@end
