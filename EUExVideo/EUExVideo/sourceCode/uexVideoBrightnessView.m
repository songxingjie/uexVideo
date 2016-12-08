/**
 *
 *	@file   	: uexVideoBrightnessView.m  in EUExVideo Project .
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

#import "uexVideoBrightnessView.h"

@interface uexVideoBrightnessView()
@property (nonatomic,strong)UIView *progressView;
@property (nonatomic,strong)NSMutableArray<UIView *> *progressDots;
@property (nonatomic,strong)UIImageView *backgroundView;
@property (nonatomic,strong)UILabel *titleLabel;
@property (nonatomic,assign)BOOL isEnabled;
@end

@implementation uexVideoBrightnessView

+ (instancetype)sharedView{
    static uexVideoBrightnessView *view = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        view = [[self alloc] init];
        
    });
    return view;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        
        self.backgroundColor = [UIColor ac_ColorWithHTMLColorString:@"#CD9A9A9A"];
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        UIImageView *backgroundView = [[UIImageView alloc]initWithImage:UEX_VIDEO_IMAGE_NAMED(@"brightness")];
        [self addSubview:backgroundView];
        @weakify(self);
        [backgroundView mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.height.equalTo(@120);
            make.width.equalTo(@120);
            make.top.equalTo(self.mas_top).with.offset(20);
            make.centerX.equalTo(self.mas_centerX);
        }];
        _backgroundView = backgroundView;
        
        
        UIView *progressView = [UIView new];
        _progressDots = [NSMutableArray array];
        static NSInteger kTotalDotsCount = 18;
        static CGFloat kDotWidth = 5;
        for(int i = 0;i < kTotalDotsCount;i++){
            UIView *dotView = [UIView new];
            dotView.backgroundColor = [UIColor whiteColor];
            [progressView addSubview:dotView];
            @weakify(progressView);
            [dotView mas_updateConstraints:^(MASConstraintMaker *make) {
                @strongify(progressView);
                make.top.equalTo(progressView.mas_top);
                make.bottom.equalTo(progressView.mas_bottom);
                make.width.equalTo(@(kDotWidth));
                make.left.equalTo(progressView.mas_left).with.offset((kDotWidth + 1) * i + 1);
            }];
            [_progressDots addObject:dotView];
        }
        progressView.backgroundColor = [UIColor ac_ColorWithHTMLColorString:@"#403835"];
        [self addSubview:progressView];
        [progressView mas_updateConstraints:^(MASConstraintMaker *make) {
            @strongify(self);
            make.width.equalTo(@((kDotWidth + 1) * kTotalDotsCount + 1));
            make.height.equalTo(@4);
            make.top.equalTo(self.mas_top).with.offset(130);
            make.centerX.equalTo(self.mas_centerX);
            
        }];
        _progressView = progressView;
        
        
        UILabel *titleLabel = [[UILabel alloc]init];
        titleLabel.text = @"亮度";
        titleLabel.textColor = [UIColor ac_ColorWithHTMLColorString:@"#403835"];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.font = [UIFont systemFontOfSize:16];
        [self addSubview:titleLabel];
        [titleLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.mas_centerX);
            make.top.equalTo(self.mas_top).with.offset(10);
        }];
        _titleLabel = titleLabel;
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self];

        
        
        
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(window.mas_centerX);
            make.centerY.equalTo(window.mas_centerY).offset(-5);
            make.width.equalTo(@155);
            make.height.equalTo(@155);
            
        }];
        
        [[[NSNotificationCenter defaultCenter] rac_addObserverForName:UIDeviceOrientationDidChangeNotification object:nil]subscribeNext:^(id x) {
            CGFloat o = 0;
            if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait || [UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown || [UIDevice currentDevice].orientation == UIDeviceOrientationFaceUp) {
                o = -5;
            };
            [self mas_updateConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(window.mas_centerY).offset(o);
            }];
            [self setNeedsUpdateConstraints];
        }];
        [self hide];
        [self disable];
        RACSignal *signal = [RACObserve([UIScreen mainScreen], brightness) distinctUntilChanged];
        [signal subscribeNext:^(NSNumber *x) {
            if(!self.isEnabled){
                return;
            }
            self.alpha = 1;
            CGFloat progress = [x floatValue];
            NSInteger dotCount = progress * kTotalDotsCount ;
            for (NSInteger i = 0;i < self.progressDots.count ; i++) {
                UIView *view = self.progressDots[i];
                if (i <= dotCount) {
                    view.hidden = NO;
                }else{
                    view.hidden = YES;
                }
            }
        }];
        [[signal throttle:1.5] subscribeNext:^(id x) {
            if(!self.isEnabled){
                return;
            }
            if (self.alpha == 1) {
                [UIView animateWithDuration:0.8 animations:^{
                    self.alpha = 0;
                }];
            }
        }];

    }
    return self;
}






- (void)hide{
    self.alpha = 0;
}

- (void)enable{
    self.isEnabled = YES;
}
- (void)disable{
    self.isEnabled = NO;
}
@end
