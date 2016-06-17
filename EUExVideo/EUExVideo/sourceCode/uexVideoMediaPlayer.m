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
#import "EUtility.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "JSON.h"
#import "EUExBaseDefine.h"
#import "uexVideoPlayerView.h"
#import "WidgetOneDelegate.h"
#import "ACEBaseViewController.h"
@interface uexVideoMediaPlayer()<uexVideoPlayerViewDelegate>
@property (nonatomic,weak) EUExVideo *euexObj;
@property (nonatomic,strong)RACDisposable *VCConfig;
@property (nonatomic,strong)uexVideoPlayerView *playerView;
@property (nonatomic,strong)NSString *inPath;
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

- (void)openWithFrame:(CGRect)frame path:(NSString *)inPath startTime:(CGFloat)startTime {
    
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
    [[self rac_signalForSelector:@selector(playerViewDidEnterFullScreen:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)]subscribeNext:^(id x) {
        @strongify(self);
        [self resetConfig];
        __kindof ACEBaseViewController *VC = (__kindof ACEBaseViewController *)theApp.drawerController;
        if (![VC respondsToSelector:@selector(canAutorotate)] || ![VC respondsToSelector:@selector(isStatusBarHidden)]) {
            return;
        }
        BOOL canAutoRotate = VC.canAutorotate;
        BOOL isStatusBarHidden = VC.isStatusBarHidden;
        VC.canAutorotate = NO;
        VC.isStatusBarHidden = YES;
        [VC setNeedsStatusBarAppearanceUpdate];
        self.VCConfig = [RACDisposable disposableWithBlock:^{
            VC.canAutorotate = canAutoRotate;
            VC.isStatusBarHidden = isStatusBarHidden;
            [VC setNeedsStatusBarAppearanceUpdate];
        }];
    }];
    [[self rac_signalForSelector:@selector(playerViewWillExitFullScreen:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)]subscribeNext:^(id x) {
        @strongify(self);
        [self resetConfig];
    }];
    [[self rac_signalForSelector:@selector(playViewCloseButtonDidClick:) fromProtocol:@protocol(uexVideoPlayerViewDelegate)]subscribeNext:^(id x) {
        @strongify(self);
        [self close];
    }];
    [[self rac_willDeallocSignal]subscribeCompleted:^{
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
    [self.playerView seekToTime:startTime];
    if (self.autoStart) {
        [self.playerView playWhenPrepared];
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
