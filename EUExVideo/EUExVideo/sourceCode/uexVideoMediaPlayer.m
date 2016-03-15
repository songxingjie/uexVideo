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
@interface uexVideoMediaPlayer()<MPMediaPickerControllerDelegate>
@property (nonatomic,assign) NSInteger startTime;
@property (nonatomic,assign) CGFloat frequency;
@property (nonatomic,strong) MPMoviePlayerViewController *playerViewController;
@property (nonatomic,weak) EUExVideo *euexObj;
@end
@implementation uexVideoMediaPlayer

- (instancetype)initWithEuex:(EUExVideo *)euexObj startTime:(NSInteger)startTime frequency:(CGFloat)frequency
{
    self = [super init];
    if (self) {
        _euexObj = euexObj;
        _startTime = startTime;
        _frequency = frequency;
    }
    return self;
}

- (void)open:(NSString *)inPath{
    inPath = [inPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *movieURL = nil;
    if ([inPath.lowercaseString hasPrefix:@"http://"] || [inPath.lowercaseString hasPrefix:@"https://"]) {
        movieURL = [NSURL URLWithString:inPath];
    }
    else {
        if (![[NSFileManager defaultManager] fileExistsAtPath:inPath]) {
            [self.euexObj jsFailedWithOpId:0 errorCode:1210102 errorDes:UEX_ERROR_DESCRIBE_FILE_EXIST];
            return;
        }
        movieURL = [NSURL fileURLWithPath:inPath];
    }
    if (!movieURL || ![movieURL scheme]){
         [self.euexObj jsFailedWithOpId:0 errorCode:1210103 errorDes:UEX_ERROR_DESCRIBE_FILE_FORMAT];
        return;
    }
    [AVPlayer playerWithURL:<#(nonnull NSURL *)#>]
    
    self.playerViewController = [[MPMoviePlayerViewController alloc]initWithContentURL:movieURL];
    
   /*
    
        self.player=[[AVPlayerViewController alloc]init];
        self.player.delegate=self;
        AVPlayer *movePlayer=[[AVPlayer alloc] initWithURL:movieURL];
        CMTime startT = CMTimeMake(_startTime,1);
        [movePlayer seekToTime:startT];
        self.player.player=movePlayer;
        [self.player.player play];
        @weakify(self);
        [self.player.player addPeriodicTimeObserverForInterval:CMTimeMake(_frequency, 1) queue:NULL usingBlock:^(CMTime time){
            float playedTime = self.player.player.currentTime.value/self.player.player.currentTime.timescale;
            [euexObj uexVideoWithFunction:@"onPlayedWithTime" result:[@{@"playedTime":@(playedTime)} JSONFragment]];
        }];
        [EUtility brwView:euexObj.meBrwView presentModalViewController:self.player animated:YES];
    
    */
    
}

@end
