//
//  mediaPlayer.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "MediaPlayer.h"
#import "EUExVideo.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"
#import <ReactiveCocoa.framework/ReactiveCocoa.h>
@interface MediaPlayer()
@property (nonatomic,weak)EUExVideo *euexObj;
@property (nonatomic,strong)MPMoviePlayerViewController *playerViewController;
@property (nonatomic,strong)AVPlayerViewController *player;
@property (nonatomic,assign)NSInteger startTime;
@property (nonatomic,assign)CGFloat frequency;
@end

@implementation MediaPlayer
- (instancetype)initWithEuex:(EUExVideo *)euexObj startTime:(float)startTime frequency:(int)frequency
{
    self = [super init];
    if (self) {
        _euexObj = euexObj;
        _startTime=startTime;
        _frequency=frequency;
    }
    return self;
}



-(void)open:(NSString*)inPath{

	NSURL *movieURL = nil;
	if ([inPath hasPrefix:@"http:"]) {// || [moviePath hasPrefix:@"rtsp:"]) {
        inPath = [inPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		movieURL = [NSURL URLWithString:inPath];
	}
	else {
		if (![[NSFileManager defaultManager] fileExistsAtPath:inPath]) {
			[self.euexObj jsFailedWithOpId:0 errorCode:1210102 errorDes:UEX_ERROR_DESCRIBE_FILE_EXIST];
			return;
		}
		movieURL = [NSURL fileURLWithPath:inPath];
	}
	if (movieURL&&[movieURL scheme])
	{
        self.player=[[AVPlayerViewController alloc]init];
        self.player.delegate=self;
        AVPlayer *movePlayer=[[AVPlayer alloc] initWithURL:movieURL];
        CMTime startT = CMTimeMake(_startTime,1);
        [movePlayer seekToTime:startT];
        self.player.player=movePlayer;
        [self.player.player play];
        @weakify(self);
        [self.player.player addPeriodicTimeObserverForInterval:CMTimeMake(_frequency, 1) queue:NULL usingBlock:^(CMTime time){
            float playedTime=self.player.player.currentTime.value/self.player.player.currentTime.timescale;
            [euexObj uexVideoWithFunction:@"onPlayedWithTime" result:[@{@"playedTime":@(playedTime)} JSONFragment]];
        }];
        [EUtility brwView:euexObj.meBrwView presentModalViewController:self.player animated:YES];
	}else{
		[euexObj jsFailedWithOpId:0 errorCode:1210103 errorDes:UEX_ERROR_DESCRIBE_FILE_FORMAT];
	}
}
@end
