//
//  mediaPlayer.h
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "JSON.h"
@class EUExVideo;
@interface MediaPlayer : NSObject <MPMediaPickerControllerDelegate,AVPlayerViewControllerDelegate>

-(void)open:(NSString*)inPath;
-(instancetype)initWithEuex:(EUExVideo *)euexObj_ startTime:(float)startTime frequency:(int)frequency;


@end
