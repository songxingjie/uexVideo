/**
 *
 *	@file   	: uexVideoPlayerMaskView.m  in EUExVideo Project .
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

#import "uexVideoPlayerMaskView.h"
#import "uexVideoPlayerView.h"
@interface uexVideoPlayerMaskView()

@property (nonatomic,strong)UIView *topGradientView;
@property (nonatomic,strong)CAGradientLayer *topLayer;
@property (nonatomic,strong)UIView *bottomGradientView;
@property (nonatomic,strong)CAGradientLayer *bottomLayer;

@property (nonatomic,strong)UIProgressView *progressView;
//@property (nonatomic,strong)UIProgressView *bufferedProgressView;//暂时先不做

@property (nonatomic,strong)UIView *optionView;

@property (nonatomic,strong)UIView *buttonView;//此view用来约束2个button的大小，无实际UI

@property (nonatomic,strong)UILabel *currentTimeLabel;
@property (nonatomic,strong)UILabel *totalTimeLabel;
@property (nonatomic,strong)UIButton *fullScreenButton;
@property (nonatomic,strong)UIButton *playButton;
@property (nonatomic,strong)UISlider *progressSlider;

@property (nonatomic,strong)RACDisposable *showViewDisposable;


@property (nonatomic,weak)uexVideoPlayerView *player;
@end

@implementation uexVideoPlayerMaskView

- (instancetype)initWithPlayerView:(uexVideoPlayerView *)playerView{
    self = [super init];
    if (self) {
        self.userInteractionEnabled = YES;
        _player = playerView;
        [self setupBackgroundUI];
        [self setupPlayButton];
        [self setupFullScreenButton];
        [self setupLabel];
        [self setupProgressSlider];
    }
    return self;
}

- (void)setFullScreenButtonHidden:(BOOL)isHidden{
    self.fullScreenButton.hidden = isHidden;
}

- (void)setProgress:(CGFloat)progress{
    self.progressSlider.value = progress;
}

- (void)setShowViewSignal:(RACSignal *)signal{
    NSMutableArray *signals = [NSMutableArray array];
    [signals addObject:self.playButtonClickSignal];
    [signals addObject:self.progressSliderValueChangeSignal];
    [signals addObject:self.fullScreenButtonClickSignal];
    if (signal) {
        [signals addObject:signal];
    }
    if (self.showViewDisposable) {
        [self.showViewDisposable dispose];
    }
    
    RACSignal *showSignal = [RACSignal merge:signals];
    RACDisposable *show = [showSignal.deliverOnMainThread subscribeNext:^(id x) {
        self.alpha = 1;
    }];
    RACDisposable *hide = [[showSignal throttle:3].deliverOnMainThread subscribeNext:^(id x) {
        if (self.alpha == 1) {
            [UIView animateWithDuration:1 animations:^{
                self.alpha = 0;
            }];
        }
    }];
    self.showViewDisposable = [RACDisposable disposableWithBlock:^{
        [show dispose];
        [hide dispose];
    }];
}

- (void)setupBackgroundUI{
    CAGradientLayer *topLayer = [CAGradientLayer layer];
    topLayer.startPoint    = CGPointMake(1, 0);
    topLayer.endPoint      = CGPointMake(1, 1);
    topLayer.colors        = @[ (__bridge id)[UIColor blackColor].CGColor,(__bridge id)[UIColor clearColor].CGColor];
    topLayer.locations     = @[@(0.0f) ,@(1.0f)];
    [self.topGradientView.layer addSublayer:topLayer];
    _topLayer = topLayer;
    
    CAGradientLayer *bottomLayer = [CAGradientLayer layer];
    bottomLayer.startPoint = CGPointMake(0, 0);
    bottomLayer.endPoint   = CGPointMake(0, 1);
    bottomLayer.colors     = @[(__bridge id)[UIColor clearColor].CGColor,(__bridge id)[UIColor blackColor].CGColor];
    bottomLayer.locations  = @[@(0.0f) ,@(1.0f)];
    [self.bottomGradientView.layer addSublayer:bottomLayer];
    _bottomLayer = bottomLayer;
}

- (void)setupPlayButton{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [button setImage:UEX_VIDEO_IMAGE_NAMED(@"play") forState:UIControlStateNormal];
    [button setImage:UEX_VIDEO_IMAGE_NAMED(@"pause") forState:UIControlStateSelected];
    
    [[[RACObserve(self.player, isPlaying) distinctUntilChanged]deliverOnMainThread]subscribeNext:^(NSNumber *x) {
        BOOL isPlaying = [x boolValue];
        if (isPlaying) {
            button.selected = YES;
        }else{
            button.selected = NO;
        }
    }];
    [self.optionView addSubview:button];
    @weakify(self);
    [button mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.left.equalTo(self.optionView.mas_left).with.offset(10);
        make.centerY.equalTo(self.optionView.mas_centerY);
        make.width.equalTo(self.buttonView.mas_width);
        make.height.equalTo(self.buttonView.mas_width);
    }];
    
    self.playButtonClickSignal = [button rac_signalForControlEvents:UIControlEventTouchUpInside].publish.autoconnect;
    self.playButton = button;
}

- (void)setupLabel{
    self.currentTimeLabel = [self makeTimeLabel];
    self.totalTimeLabel = [self makeTimeLabel];

    
    RACSignal *progressChangeSignal = [RACSignal merge:@[self.progressSliderValueChangeSignal,RACObserve(self.progressSlider, value)]];
    RACSignal *durationChangeSignal = RACObserve(self.player, duration);
    
    RAC(self.currentTimeLabel,text) =
        [[[[RACSignal combineLatest:@[progressChangeSignal,durationChangeSignal] reduce:^id(NSNumber *progress,NSNumber *duration){
        return @((NSInteger)floorf(duration.floatValue * progress.floatValue));
            }]
            distinctUntilChanged]
            deliverOnMainThread]
            map:^id(NSNumber *currentTime) {
                NSInteger secs = currentTime.integerValue;
                return [uexVideoHelper stringFromSeconds:secs];
            }];
    RAC(self.totalTimeLabel,text) = [[[durationChangeSignal distinctUntilChanged]deliverOnMainThread]map:^id(id value) {
        CGFloat duration = [value floatValue];
        NSInteger secs = (NSInteger)ceilf(duration);
        return [uexVideoHelper stringFromSeconds:secs];
    }];
    @weakify(self);
    [self.optionView addSubview:self.currentTimeLabel];
    [self.currentTimeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.centerY.equalTo(self.optionView.mas_centerY);
        make.left.equalTo(self.playButton.mas_right).with.offset(5);
    }];
    
    [self.optionView addSubview:self.totalTimeLabel];
    
    [self.totalTimeLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.centerY.equalTo(self.optionView.mas_centerY);
        make.right.equalTo(self.fullScreenButton.mas_left).with.offset(-5);
    }];
    
    
}

- (UILabel *)makeTimeLabel{
    UILabel *label = [[UILabel alloc]init];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:10];
    label.numberOfLines = 1;
    label.textAlignment = NSTextAlignmentCenter;
    return label;
}


- (void)setupProgressSlider{
    [self.optionView addSubview:self.progressView];
    [self.optionView insertSubview:self.progressSlider aboveSubview:self.progressView];
    @weakify(self)
    [self.progressView mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.left.equalTo(self.currentTimeLabel.mas_right).with.offset(3);
        make.right.equalTo(self.totalTimeLabel.mas_left).with.offset(-3);
        make.centerY.equalTo(self.optionView.mas_centerY).with.offset(1);
        make.height.equalTo(@1.5);
    }];
    
    [self.progressSlider mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.left.equalTo(self.currentTimeLabel.mas_right).with.offset(3);
        make.right.equalTo(self.totalTimeLabel.mas_left).with.offset(-3);
        make.centerY.equalTo(self.optionView.mas_centerY);
        make.height.equalTo(self.optionView.mas_height).with.offset(-4);
    }];
    
    
    
}

- (void)setupFullScreenButton{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setBackgroundImage:UEX_VIDEO_IMAGE_NAMED(@"fullscreen") forState:UIControlStateNormal];
    [button setBackgroundImage:UEX_VIDEO_IMAGE_NAMED(@"nonfullscreen") forState:UIControlStateSelected];
    [[[RACObserve(self.player, isFullScreen) distinctUntilChanged]deliverOnMainThread]subscribeNext:^(NSNumber *x) {
        BOOL isFullScreen = [x boolValue];
        if (isFullScreen) {
            button.selected = YES;
        }else{
            button.selected = NO;
        }
    }];
    [self.optionView addSubview:button];
    
    @weakify(self);
    [button mas_updateConstraints:^(MASConstraintMaker *make) {
        @strongify(self);
        make.right.equalTo(self.optionView.mas_right).with.offset(-10);
        make.centerY.equalTo(self.optionView.mas_centerY);
        make.width.equalTo(self.buttonView.mas_width);
        make.height.equalTo(self.buttonView.mas_width);
    }];
    _fullScreenButton = button;
    self.fullScreenButtonClickSignal = [button rac_signalForControlEvents:UIControlEventTouchUpInside].publish.autoconnect;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    self.topLayer.frame = self.topGradientView.bounds;
    self.bottomLayer.frame = self.bottomGradientView.bounds;
}


- (UIView *)topGradientView{
    if (!_topGradientView) {
        UIView *view = [UIView new];
        //view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        @weakify(self);
        [view mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.top.equalTo(self.mas_top);
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.height.equalTo(@50);

        }];
        _topGradientView = view;
    }
    return _topGradientView;
}

- (UIView *)bottomGradientView{
    if (!_bottomGradientView) {
        UIView *view = [UIView new];
        //view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        @weakify(self);
        [view mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.bottom.equalTo(self.mas_bottom);
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
            make.height.equalTo(@50);
        }];
        _bottomGradientView = view;
    }
    return _bottomGradientView;
}



- (UIView *)optionView{
    if (!_optionView) {
        UIView *view = [UIView new];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self insertSubview:view aboveSubview:self.bottomGradientView];
        @weakify(self);
        [view mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.edges.equalTo(self.bottomGradientView);
        }];
        _optionView = view;
    }
    return _optionView;
}


- (UIView *)buttonView{
    if (!_buttonView) {
        UIView *view = [UIView new];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        view.backgroundColor = [UIColor clearColor];
        @weakify(self);
        [view mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.width.greaterThanOrEqualTo(@5).with.priorityHigh();
            make.width.lessThanOrEqualTo(self.optionView.mas_height).with.offset(-4);
            make.width.lessThanOrEqualTo(self.mas_width).multipliedBy(0.3);
            make.height.equalTo(@0);

        }];
        _buttonView = view;
    }
    return _buttonView;
}

- (UISlider *)progressSlider{
    if (!_progressSlider) {
        UISlider *slider = [[UISlider alloc] init];
        slider.translatesAutoresizingMaskIntoConstraints = NO;
        slider.maximumValue = 1;
        slider.maximumTrackTintColor = [EUtility colorFromHTMLString:@"#4D4D4D4D"];
        
        slider.minimumValue = 0;
        slider.minimumTrackTintColor = [UIColor whiteColor];
        slider.value = 0;
        [slider setThumbImage:UEX_VIDEO_IMAGE_NAMED(@"dot") forState:UIControlStateNormal];
        @weakify(self);
        RAC(slider,value) = [[RACObserve(self.player, currentTime) filter:^BOOL(id value) {
            return !slider.isTracking;
        }]map:^id(id value) {
            @strongify(self);
            if (self.player.duration == 0) {
                return @0;
            }
            return @([value floatValue]/self.player.duration);
        }];
        _progressSlider = slider;
    }
    return _progressSlider;
}



- (UIProgressView *)progressView{
    if (!_progressView) {
        UIProgressView *progressView = [[UIProgressView alloc]init];
        progressView.translatesAutoresizingMaskIntoConstraints = NO;
        progressView.trackTintColor = [UIColor clearColor];
        progressView.progressTintColor = [EUtility colorFromHTMLString:@"#99999999"];
        RAC(progressView,progress) = [RACSignal combineLatest:@[RACObserve(self.player, bufferedDuration),RACObserve(self.player, duration)] reduce:^id(NSNumber *bufferedNumber,NSNumber *totalNumber){
            CGFloat buffered = bufferedNumber.floatValue;
            CGFloat total = totalNumber.floatValue;
            return @((total == 0) ? 0 : buffered / total);
        }];
        _progressView = progressView;
    }
    return _progressView;
}

- (RACSignal *)progressSliderValueChangeSignal{
    if (!_progressSliderValueChangeSignal) {
        _progressSliderValueChangeSignal = [[self.progressSlider rac_signalForControlEvents:UIControlEventValueChanged]map:^id(UISlider *slider) {
            CGFloat progress = slider.value;
            //NSLog(@"%@",@(progress));
            return @(progress);
        }].publish.autoconnect;
    }
    return _progressSliderValueChangeSignal;
}

- (RACSignal *)progressSliderStartDraggingSignal{
    if (!_progressSliderStartDraggingSignal) {
        _progressSliderStartDraggingSignal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [[self.progressSlider rac_signalForControlEvents:UIControlEventTouchDown] subscribeNext:^(id x) {
                [subscriber sendNext:@YES];
            }];
            [[self.progressSlider rac_signalForControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside] subscribeNext:^(id x) {
                [subscriber sendNext:@NO];
            }];
            return nil;
        }].publish.autoconnect;
    }
    return _progressSliderStartDraggingSignal;
}


@end
