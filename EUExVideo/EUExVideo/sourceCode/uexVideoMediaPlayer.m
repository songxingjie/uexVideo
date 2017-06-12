/**
 *
 *	@file   	: uexVideoMediaPlayer.m  in EUExVideo Project .
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

#import "uexVideoMediaPlayer.h"
#import "EUExVideo.h"

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>


#import "uexVideoPlayerView.h"
#import "WidgetOneDelegate.h"
#import "ACEBaseViewController.h"
#import "ACEUINavigationController.h"

@interface uexVideoMediaPlayer()<uexVideoPlayerViewDelegate>
@property (nonatomic,weak) EUExVideo *euexObj;
@property (nonatomic,strong)RACDisposable *VCConfig;
@property (nonatomic,strong)uexVideoPlayerView *playerView;
@property (nonatomic,strong)NSString *inPath;
@property (nonatomic,assign)BOOL rotatedFromPortrait;
@property (nonatomic,strong)UIView *rootView;
@property (nonatomic,assign)CGRect normalFrame;
@property (nonatomic,assign)ACEInterfaceOrientation orientation;
@end


@implementation uexVideoMediaPlayer

- (instancetype)initWithEUExVideo:(EUExVideo *)euexObj
{
    self = [super init];
    if (self) {
        _euexObj = euexObj;
        
    }
    return self;
}

- (void)openWithFrame:(CGRect)frame path:(NSString *)inPath{
    
    inPath = [inPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    self.inPath = inPath;
    NSURL *movieURL = nil;
    if ([inPath.lowercaseString hasPrefix:@"http://"] || [inPath.lowercaseString hasPrefix:@"https://"]) {
        movieURL = [NSURL URLWithString:inPath];
    }
    else {
        movieURL = [NSURL fileURLWithPath:inPath];
    }
    if (self.playerView) {
        [self close];
    }
    self.playerView = [[uexVideoPlayerView alloc]initWithFrame:frame URL:movieURL];
    self.playerView.delegate = self;
    @weakify(self);
    [[self rac_signalForSelector:@selector(playerViewEnterFullScreenButtonDidClick:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)]subscribeNext:^(id x) {

        @strongify(self);
        [self resetConfig];
        __kindof ACEBaseViewController *controller = (__kindof ACEBaseViewController *)[self.euexObj.webViewEngine viewController];
        ACEUINavigationController *navi = (ACEUINavigationController *)controller.navigationController;
        
        if (![navi respondsToSelector:@selector(canAutoRotate)] || ![navi respondsToSelector:@selector(supportedOrientation)]  || ![controller respondsToSelector:@selector(shouldHideStatusBarNumber)]) {
            [NSException raise:@"uexVideoScreenRotateException" format:@"this uexVideo requires engine version 4.1+"];
            return;
        }
        BOOL canAutoRotate = navi.canAutoRotate;
        self.orientation = navi.supportedOrientation;
        NSNumber *shouldHideStatusBarNumber = controller.shouldHideStatusBarNumber;
        navi.supportedOrientation = ACEInterfaceOrientationLandscapeLeft;
        navi.canAutoRotate = YES;
        UIInterfaceOrientation deviceOrientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
        if (deviceOrientation != UIInterfaceOrientationLandscapeRight && deviceOrientation != UIInterfaceOrientationLandscapeLeft) {
            [self.playerView rotateToOrientation:UIInterfaceOrientationLandscapeRight];
            self.rotatedFromPortrait = YES;
        }
        self.rootView = self.playerView.superview;
        self.normalFrame = self.playerView.frame;
        [[UIApplication sharedApplication].keyWindow addSubview:self.playerView];
        self.playerView.frame = [UIScreen mainScreen].bounds;
        [self.playerView layoutIfNeeded];
        
        navi.canAutoRotate = NO;
        controller.shouldHideStatusBarNumber = @YES;
        [controller setNeedsStatusBarAppearanceUpdate];
        self.VCConfig = [RACDisposable disposableWithBlock:^{
            navi.canAutoRotate = canAutoRotate;
            controller.shouldHideStatusBarNumber = shouldHideStatusBarNumber;
            [controller setNeedsStatusBarAppearanceUpdate];
        }];
    }];
    [[self rac_signalForSelector:@selector(playerViewExitFullScreenButtonDidClick:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)]subscribeNext:^(id x) {
        @strongify(self);
        ACEUINavigationController *navi = (ACEUINavigationController *)[self.euexObj.webViewEngine viewController].navigationController;
        navi.supportedOrientation = self.orientation;
        navi.canAutoRotate = YES;
        if (self.rotatedFromPortrait) {
            [self.playerView rotateToOrientation:UIInterfaceOrientationPortrait];
        }
        self.rotatedFromPortrait = NO;
        
        
        self.playerView.frame = self.normalFrame;
        [self.rootView addSubview:self.playerView];
        self.normalFrame = CGRectZero;
        self.rootView = nil;
        [self resetConfig];
    }];
    [[self rac_signalForSelector:@selector(playerViewCloseButtonDidClick:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)]subscribeNext:^(id x) {
        @strongify(self);
        [self close];
    }];
    [[self rac_signalForSelector:@selector(playerViewDidFinishPlaying:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)] subscribeNext:^(id x) {
        @strongify(self);
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onPlayerFinish" arguments:nil];
        
    }];
    [[[self rac_signalForSelector:@selector(playerViewDidReachEndTime:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)] throttle:0.3] subscribeNext:^(id x) {
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onPlayerEndTime" arguments:nil];
    }];
    [[self rac_willDeallocSignal] subscribeCompleted:^{
        @strongify(self);
        [self resetConfig];
    }];
    
    [self.playerView setFullScreenBottonHidden:!self.showScaleButton];
    [self.playerView setCloseButtonHidden:!self.showCloseButton];
    
    if (self.isScrollWithWeb) {
        [[self.euexObj.webViewEngine webScrollView]addSubview:self.playerView];
        
    }else{
        [[self.euexObj.webViewEngine webView]addSubview:self.playerView];
    }
    if (self.forceFullScreen) {
        [self.playerView forceFullScreen];
    }
    [self.playerView seekToTime:self.startTime];
    if (self.autoStart) {
        [self.playerView playWhenPrepared];
    }
    if (self.endTime > 0) {
        self.playerView.endTime = self.endTime;
    }
    
    
    [RACObserve(self.playerView, status).distinctUntilChanged subscribeNext:^(id x) {
        @strongify(self);
        NSDictionary *dict = @{@"status":x};
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onPlayerStatusChange" arguments:ACArgsPack(dict.ac_JSONFragment)];
        
    }];
}

- (void)resetConfig{
    if (self.VCConfig) {
        [self.VCConfig dispose];
        self.VCConfig = nil;
    }
}

- (void)close{
    if(!self.playerView){
        return;
    }
    [self.playerView close];
    NSDictionary *dict = @{
                           @"src":self.inPath,
                           @"currentTime":@((NSInteger)self.playerView.currentTime)
                           };
    [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onPlayerClose" arguments:ACArgsPack(dict.ac_JSONFragment)];
    [self.playerView removeFromSuperview];
    [self resetConfig];
    self.playerView = nil;
    self.inPath = nil;
    self.euexObj.player = nil;
    
}



@end
