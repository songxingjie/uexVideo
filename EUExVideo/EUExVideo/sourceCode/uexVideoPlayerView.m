/**
 *
 *	@file   	: uexVideoPlayerView.m  in EUExVideo Project .
 *
 *	@author 	: CeriNo.
 * 
 *	@date   	: Created on 16/3/15.
 *
 *	@copyright 	: 2016 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "uexVideoPlayerView.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <libkern/OSAtomic.h>
#import "uexVideoPlayerMaskView.h"
#import "uexVideoBrightnessView.h"

@interface uexVideoPlayerView()

@property (nonatomic,strong)NSURL *url;
@property (nonatomic,strong)AVPlayer *player;
@property (nonatomic,strong)AVPlayerItem *playerItem;
@property (nonatomic,strong)AVPlayerLayer *playerLayer;
@property (nonatomic,strong)UIActivityIndicatorView *activityIndicator;
@property (nonatomic,strong)uexVideoPlayerMaskView *maskView;
@property (nonatomic,assign,readwrite)uexVideoPlayerViewStatus status;
@property (nonatomic,assign,readwrite)CGFloat currentTime;
@property (nonatomic,assign,readwrite)BOOL isFullScreen;
@property (nonatomic,assign,readwrite)BOOL isPlaying;
@property (nonatomic,assign)BOOL isPausedByUser;

@property (nonatomic,assign)BOOL isForcedFullScreen;
@property (nonatomic,assign)BOOL playWhenReady;
@property (nonatomic,assign)CGRect normalFrame;

@property (nonatomic,strong)UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic,strong)RACSignal *singleTapSignal;
@property (nonatomic,strong)RACSignal *panSignal;
@property (nonatomic,assign)BOOL rotatedFromPortrait;
@property (nonatomic,strong)UILabel *panLabel;
@property (nonatomic,strong)UISlider *volumeSlider;
@property (nonatomic,strong)MPVolumeView *systemVolumeView;
@property (nonatomic,strong)UIButton *closeButton;
@end



typedef NS_ENUM(NSInteger,uexVideoPlayerViewPanGestureAction){
    uexVideoPlayerViewPanGestureShouldIgnore,
    uexVideoPlayerViewPanGestureProgressControl,
    uexVideoPlayerViewPanGestureAdjustVolume,
    uexVideoPlayerViewPanGestureAdjustBrightness,
};

static OSSpinLock lock;

@implementation uexVideoPlayerView

+ (void)initialize{
    if ([self class] == [uexVideoPlayerView class]) {
        lock = OS_SPINLOCK_INIT;
    }
}

- (instancetype)initWithFrame:(CGRect)frame URL:(NSURL *)url
{
    self = [super initWithFrame:frame];
    if (self) {
        _url = url;
        _isPausedByUser = YES;
        self.backgroundColor = [UIColor blackColor];
        [self setupPlayer];
        [self setupMaskView];
        self.closeButton.hidden = NO;
        [self.maskView setFullScreenButtonHidden:NO];
        [self setupGestures];
        [[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: NULL];
    }
    return self;
}



- (void)forceFullScreen{
    self.isForcedFullScreen = YES;
    [self setCloseButtonHidden:NO];
    [self enterFullScreen];
}

- (void)setCloseButtonHidden:(BOOL)isHidden{
    if (isHidden && !self.isFullScreen) {
        self.closeButton.hidden = YES;
    }else{
        self.closeButton.hidden = NO;
    }
}

- (void)setFullScreenBottonHidden:(BOOL)isHidden{
    [self.maskView setFullScreenButtonHidden:isHidden];
    
}

- (void)playWhenPrepared{
    if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
        [self play];
    }else{
        self.playWhenReady = YES;
    }
}

- (void)play{
    self.isPausedByUser = NO;
    [_player play];
    self.isPlaying = YES;
    self.status = uexVideoPlayerViewStatusPlaying;
}
- (void)pause{
    [_player pause];
    self.isPlaying = NO;
    self.status = uexVideoPlayerViewStatusPaused;
}
- (void)userChangePlayStatus{
    if(self.isPlaying){
        [self pause];
        self.isPausedByUser = YES;
    }else{
        [self play];
    }
}

- (void)close{
    [self pause];
    if(self.isFullScreen){
        [self exitFullScreen];
    }
    [self removeFromSuperview];
}

- (void)enterFullScreen{
    OSSpinLockLock(&lock);
    if (!self.isFullScreen) {

        self.normalFrame = self.frame;
        UIInterfaceOrientation orientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
        if (orientation != UIInterfaceOrientationLandscapeRight && orientation != UIInterfaceOrientationLandscapeLeft) {
            [self rotateToOrientation:UIInterfaceOrientationLandscapeRight];
            self.rotatedFromPortrait = YES;
        }
        //考虑到当前view可能在一个scrollView里的情况 不能直接用[UIScreen mainScreen].bounds
        CGRect rect = [[UIApplication sharedApplication].keyWindow convertRect:[UIScreen mainScreen].bounds toView:self.superview];
        self.frame = rect;

        self.isFullScreen = YES;
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerViewDidEnterFullScreen:)]){
            [self.delegate playerViewDidEnterFullScreen:self];
        }

    }
    OSSpinLockUnlock(&lock);
    
    
}
- (void)exitFullScreen{
    OSSpinLockLock(&lock);
    if (self.isFullScreen) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(playerViewWillExitFullScreen:)]){
            [self.delegate playerViewWillExitFullScreen:self];
        }
        if (self.rotatedFromPortrait) {
            [self rotateToOrientation:UIInterfaceOrientationPortrait];
            self.rotatedFromPortrait = NO;
        }
        self.frame = self.normalFrame;
        self.isFullScreen = NO;

    }
    OSSpinLockUnlock(&lock);
}



- (void)setupPlayer{
    self.playerItem  = [AVPlayerItem playerItemWithURL:self.url];
    self.player      = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    if([self.playerLayer.videoGravity isEqualToString:AVLayerVideoGravityResizeAspect]){
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }else{
        self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
    [self.layer insertSublayer:self.playerLayer atIndex:0];
    @weakify(self);
    RAC(self,duration) = [RACObserve(self.playerItem, duration) map:^id(id x) {
        CMTime time = [x CMTimeValue];
        CGFloat duration = (CGFloat)time.value / (CGFloat)time.timescale;
        return @(duration);
    }];
    RAC(self,bufferedDuration) = [RACObserve(self.playerItem, loadedTimeRanges) map:^id(NSArray *loadedTimeRanges) {
        CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds  = CMTimeGetSeconds(timeRange.duration);
        CGFloat bufferedSeconds = startSeconds + durationSeconds;

        return @(bufferedSeconds);
    }];
    [[RACSignal interval:0.2 onScheduler:[RACScheduler mainThreadScheduler]].repeat
     subscribeNext:^(id x) {//更新currentTime 间隔为0.2s
         @strongify(self);
        CMTime time = self.player.currentItem.currentTime;
        self.currentTime = (CGFloat)time.value / (CGFloat)time.timescale;
    }];
    [RACObserve(self.playerItem, status)
     subscribeNext:^(id x) {
         @strongify(self);
        AVPlayerItemStatus status = [x integerValue];
        switch (status) {
            case AVPlayerItemStatusUnknown: {
                break;
            }
            case AVPlayerItemStatusReadyToPlay: {
                if (self.playWhenReady) {
                    [self play];
                }
                break;
            }
            case AVPlayerItemStatusFailed: {
                self.status = uexVideoPlayerViewStatusFailed;
                break;
            }
        }
    }];
    
    [[RACObserve(self.playerItem, isPlaybackBufferEmpty)
      filter:^BOOL(id value) {
        return [value boolValue];
    }]subscribeNext:^(id x) {
        @strongify(self);
        [self pause];
        self.status = uexVideoPlayerViewStatusBuffering;
        [self.activityIndicator startAnimating];
        __block RACDisposable *bufferingPause = [[RACSignal interval:1 onScheduler:[RACScheduler mainThreadScheduler]].repeat subscribeNext:^(id x) {
            if (self.playerItem.isPlaybackLikelyToKeepUp) {
                [self.activityIndicator stopAnimating];
                if (!self.isPausedByUser) {
                    [self play];
                }else{
                    self.status = uexVideoPlayerViewStatusPaused;
                }
                [bufferingPause dispose];
            }
        }];
    }];
    
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem]
     subscribeNext:^(id x) {
         @strongify(self);
         if (!self.isForcedFullScreen) {
             [self exitFullScreen];
         }
        [self pause];
        [self seekToTime:0];
    }];
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil]
     subscribeNext:^(id x) {
         @strongify(self);
        [self pause];
    }];
    [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIApplicationDidBecomeActiveNotification object:nil]
     subscribeNext:^(id x) {
         @strongify(self);
        if (!self.isPausedByUser) {
            [self playWhenPrepared];
        }
    }];
    

    
}
- (void)setupMaskView{
    self.maskView = [[uexVideoPlayerMaskView alloc]initWithPlayerView:self];
    [self addSubview:self.maskView];
    @weakify(self);
    [self.maskView mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.edges.equalTo(self);
    }];
    [self.maskView.playButtonClickSignal subscribeNext:^(id x) {
        @strongify(self);
        [self userChangePlayStatus];
    }];
    [self.maskView.fullScreenButtonClickSignal subscribeNext:^(id x) {
        @strongify(self);
        if(!self.isFullScreen){
            [self enterFullScreen];
        }else if(!self.isForcedFullScreen){
            [self exitFullScreen];
        }
    }];
    [self.maskView setShowViewSignal:[RACSignal merge:@[self.singleTapSignal,self.panSignal]]];

    [[self.maskView.progressSliderValueChangeSignal map:^id(id x) {
        @strongify(self);
        return @((NSInteger)nearbyintf([x floatValue] * self.duration));
        
    }].distinctUntilChanged subscribeNext:^(id x) {
        @strongify(self);
        //用map + distinctUntilChanged 进行过滤,减少seek次数,降低CPU占用
        [self seekToTime:[x integerValue]];
    }];
    [self.maskView.progressSliderStartDraggingSignal subscribeNext:^(id x) {
        @strongify(self);
        BOOL isStartDragging = [x boolValue];
        if (isStartDragging) {
            [self pause];
        }else{
            if (!self.isPausedByUser) {
                [self play];
            }
        }
    }];
    self.maskView.alpha = 0;
}



- (void)setupGestures{
    __block uexVideoPlayerViewPanGestureAction action = uexVideoPlayerViewPanGestureShouldIgnore;
    __block CGFloat sum = 0;
    @weakify(self);
    //滑动手势
    RACSignal *panSignal = [self.panSignal map:^id(UIPanGestureRecognizer *panGes) {
        @strongify(self);
        if (panGes.state == UIGestureRecognizerStateBegan) {
            //手势开始时重置状态
            self.panLabel.text = @"";
            self.panLabel.alpha = 1;
            action = uexVideoPlayerViewPanGestureShouldIgnore;
            [UEX_VIDEO_BRIGHTNESS_VIEW disable];
            self.systemVolumeView.hidden = NO;
            
            CGPoint velocty = [panGes velocityInView:self];
            CGFloat vertical = fabs(velocty.x);
            CGFloat horizental = fabs(velocty.y);
            CGPoint position = [panGes locationInView:self];
            CGFloat x = position.x / self.frame.size.width;
            CGFloat y = position.y / self.frame.size.height;
            
            if (vertical > horizental && y < 0.8) {
                sum = 0;
                action = uexVideoPlayerViewPanGestureProgressControl;
                [self pause];
            }
            if(vertical < horizental && x < 0.4) {
                [UEX_VIDEO_BRIGHTNESS_VIEW enable];
                action = uexVideoPlayerViewPanGestureAdjustBrightness;
            }
            if (vertical < horizental && x > 0.6) {
                self.systemVolumeView.hidden = YES;
                action = uexVideoPlayerViewPanGestureAdjustVolume;
            }
            
        }
        return panGes;
    }];
    //左侧竖直方向的滑动手势 调节亮度
    [[panSignal filter:^BOOL(id value) {
        return action == uexVideoPlayerViewPanGestureAdjustBrightness;
    }]subscribeNext:^(UIPanGestureRecognizer *panGes) {
        @strongify(self);
        
        [UIScreen mainScreen].brightness -= [panGes velocityInView:self].y / 10000;
    }];
    
    //右侧竖直方向的滑动手势 调节声音
    [[panSignal filter:^BOOL(id value) {
        return action == uexVideoPlayerViewPanGestureAdjustVolume;
    }]subscribeNext:^(UIPanGestureRecognizer *panGes) {
        @strongify(self);
        [UEX_VIDEO_BRIGHTNESS_VIEW hide];
        self.volumeSlider.value -= [panGes velocityInView:self].y / 10000;
    }];
    
    //水平方向的滑动手势--快进/快退
    [[panSignal filter:^BOOL(id value) {
        return action == uexVideoPlayerViewPanGestureProgressControl;
    }]subscribeNext:^(UIPanGestureRecognizer *panGes) {
        @strongify(self);
        if (panGes.state == UIGestureRecognizerStateChanged) {
            CGFloat x = [panGes velocityInView:self].x;
            sum += x/100;
        }
        NSInteger warpSec = [self warpSeconds:sum];
        CGFloat seekSec = self.currentTime + warpSec;
        if (seekSec < 0) {
            seekSec = 0;
        }
        if (seekSec > self.duration) {
            seekSec = self.duration;
        }
        self.panLabel.text = [NSString stringWithFormat:@"%@/%@",[uexVideoHelper stringFromSeconds:(NSInteger)seekSec],[uexVideoHelper stringFromSeconds:(NSInteger)self.duration]];
        if (panGes.state == UIGestureRecognizerStateEnded) {
            [self seekToTime:seekSec];
            if (!self.isPausedByUser) {
                [self play];
            }
            [UIView animateWithDuration:0.8 animations:^{
                self.panLabel.alpha = 0;
            }];
        }
       
    }];
    
    //点击事件
    [self.singleTapSignal subscribeNext:^(UITapGestureRecognizer *tapGes) {
        @strongify(self);
        if (self.maskView.alpha != 1) {
            return;
        }
        CGPoint point = [tapGes locationInView:self];
        CGSize size = self.frame.size;
        if (fabs(point.x/size.width - 0.5) > 0.3 || fabs(point.y/size.height - 0.5) > 0.25) {//只在view中间的区域才响应
            return;
        }
        [self userChangePlayStatus];
    }];
    
    //解决亮度指示无法消除的问题;
    [self.rac_willDeallocSignal subscribeNext:^(id x) {
        [UEX_VIDEO_BRIGHTNESS_VIEW hide];
        [UEX_VIDEO_BRIGHTNESS_VIEW disable];
    }];
    
}

- (NSInteger)warpSeconds:(CGFloat)sum{
    CGFloat abs = fabs(sum);
    NSInteger positive = sum / abs;
    if (abs < 5) {
        return 0;
    }
    if (abs < 50) {
        return (NSInteger)sum/10;
    }
    if (abs < 100) {
        return positive * (abs - 45);
    }
    return positive * ((2 * abs) - 145);
}

    /*
    RACSignal *verticalSignal = [self.panSignal filter:^BOOL(UIPanGestureRecognizer *panGes) {
        CGPoint veloctyPoint = [panGes velocityInView:self];
        
    }}]
*/

- (void)seekToTime:(CGFloat)time{
    NSInteger seconds = (NSInteger)nearbyintf(time);
    CMTime t = CMTimeMake(seconds, 1);
    CMTime accuracy = CMTimeMake(1, 2);//精度为0.5s
    [self.playerItem seekToTime:t toleranceBefore:accuracy toleranceAfter:accuracy];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)orientation{
    SEL selector = NSSelectorFromString([uexVideoHelper getSecretStringByKey:kUexVideoOrientationKey]);
    if ([[UIDevice currentDevice] respondsToSelector:selector]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
    
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

- (RACSignal *)singleTapSignal{
    if (!_singleTapSignal) {
        UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]init];
        _singleTapSignal = tapGes.rac_gestureSignal.publish.autoconnect;
        [self addGestureRecognizer:tapGes];
    }
    return _singleTapSignal;
}

- (RACSignal *)panSignal{
    if (!_panSignal) {
        UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc]init];
        _panSignal = panGes.rac_gestureSignal.publish.autoconnect;
        [self addGestureRecognizer:panGes];
    }
    return _panSignal;
}


- (UIActivityIndicatorView *)activityIndicator{
    if (!_activityIndicator) {
        UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc]init];
        activity.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        [self addSubview:activity];
        @weakify(self);
        [activity mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.width.equalTo(@30);
            make.height.equalTo(@30);
            make.center.equalTo(self);
        }];
        _activityIndicator = activity;
    }
    return _activityIndicator;
}

- (UILabel *)panLabel{
    if (!_panLabel) {
        _panLabel = [[UILabel alloc]init];
        _panLabel.textColor = [UIColor whiteColor];
        [self addSubview:_panLabel];
        @weakify(self);
        [_panLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.center.equalTo(self);
        }];
    }
    return _panLabel;
}



- (UISlider *)volumeSlider{
    if (!_volumeSlider) {
        MPVolumeView *volumeView = [[MPVolumeView alloc] init];
        volumeView.frame = CGRectMake(-1000, -1000, 1, 1);
        
        [self addSubview:volumeView];
        self.systemVolumeView = volumeView;
        for (UIView *view in volumeView.subviews) {
            NSString *r =[uexVideoHelper getSecretStringByKey:kUexVideoVolumeKey];
            if ([view.class.description isEqual:r]) {
                _volumeSlider = (UISlider *)view;
            }
        }
    }
    return _volumeSlider;
}



- (UIButton *)closeButton{
    if (!_closeButton) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setBackgroundImage:UEX_VIDEO_IMAGE_NAMED(@"close") forState:UIControlStateNormal];
        [self addSubview:button];
        @weakify(self);
        [[button rac_signalForControlEvents:UIControlEventTouchUpInside].publish.autoconnect subscribeNext:^(id x) {
            @strongify(self);
            if (self.delegate && [self.delegate respondsToSelector:@selector(playViewCloseButtonDidClick:)]) {
                [self.delegate playViewCloseButtonDidClick:self];
            }else{
                [self close];
            }
        }];
        [button mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.top.equalTo(self.mas_top).with.offset(5);
            make.left.equalTo(self.mas_left).with.offset(5);
            make.height.equalTo(@30);
            make.width.equalTo(@30);
        }];
        _closeButton = button;
    }
    return _closeButton;
}


@end
