//
//  EUExVideoMgr.h
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MediaPlayer.h"
@class uexVideoRecorder;
@class uexVideoMediaPlayer;

@interface EUExVideo : EUExBase {
	MediaPlayer *mPlayerObj;
}

@property (nonatomic,strong)uexVideoRecorder *recorder;
@property (nonatomic,strong)uexVideoMediaPlayer *player;


@end
