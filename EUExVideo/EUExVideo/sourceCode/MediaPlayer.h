//
//  mediaPlayer.h
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//
#import "SCRecorder.h"
#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "JSON.h"
@class EUExVideo;
@interface MediaPlayer : NSObject <MPMediaPickerControllerDelegate,AVPlayerViewControllerDelegate>{
    EUExVideo *euexObj;
    float _startTime;
    int _frequency;
}
-(void)open:(NSString*)inPath;
-(void)initWithEuex:(EUExVideo *)euexObj_ startTime:(float)startTime frequency:(int)frequency;

//@property (nonatomic,retain)EUExVideo *euexObj;
@property (nonatomic,strong)MPMoviePlayerViewController *playerViewController;
@property (nonatomic,strong)AVPlayerViewController *player;
@end
