//
//  PlayerViewController.m
//  AVExperiments
//
//  Created by Joe Hankin on 5/4/12.
//  Copyright (c) 2012 Blackboard, Inc. All rights reserved.
//

#import "PlayerViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerView : UIView {
}
@property (nonatomic, retain) AVPlayer *player;
@end

@implementation PlayerView
+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end

@interface PlayerViewController () {
    NSURL *_fileURL;
    PlayerView *_playerView;
    UIBarButtonItem *_playButton;
    AVURLAsset *_asset;
    AVPlayer *_player;
    AVPlayerItem *_playerItem;
    AVPlayerLayer *_playerLayer;
}

@end

@implementation PlayerViewController

- (id)initWithFileURL:(NSURL *)fileURL {
    self = [self init];
    if (self) {
        _fileURL = [fileURL retain];
        
    }
    return self;
}

- (void)dealloc {
    [_playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_fileURL release];
    [super dealloc];
}

#pragma mark - Interface

- (void)play {
    [_player play];
}

- (void)exit {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.navigationController popViewControllerAnimated:YES];
    });
}

#pragma mark - View Lifecycle

static const NSString *ItemStatusContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    _playerView = [[PlayerView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [_playerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.view addSubview:_playerView];
    [_playerView release];
    
    
    _playButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playButtonPress:)];
    self.navigationItem.rightBarButtonItem = _playButton;          
    [_playButton release];
    
    
    NSString *tracksKey = @"tracks";
    _asset = [[AVURLAsset URLAssetWithURL:_fileURL options:nil]  retain];
    [_asset loadValuesAsynchronouslyForKeys:[NSArray arrayWithObject:tracksKey] completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), 
        ^{
            NSError *error = nil;
            AVKeyValueStatus status = [_asset statusOfValueForKey:tracksKey error:&error];
            if (status == AVKeyValueStatusLoaded) {
                _playerItem = [[AVPlayerItem playerItemWithAsset:_asset] retain];
                [_playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
                
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
                _player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
                [_playerView setPlayer:_player];
            } else {
                NSLog(@"Asset is all FUCKED: %@", [error localizedDescription]);
            }
        });
    }];
}



- (void)viewDidUnload
{
    [_playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_player release];
    [_asset release];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Button Actions

- (void)playButtonPress:(id)sender {
    [self play];
}

#pragma mark - UI Updates

- (void)syncUI {
    if (_player.currentItem != nil && [_player.currentItem status] == AVPlayerItemStatusReadyToPlay) {
        _playButton.enabled = YES;
    } else {
        _playButton.enabled = NO;
    }
}


#pragma mark - Observation

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [_player seekToTime:kCMTimeZero];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncUI];
                       });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object
                           change:change context:context];
    return;
}


@end
