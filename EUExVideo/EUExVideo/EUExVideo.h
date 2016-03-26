//
//  EUExVideoMgr.h
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "EUExBase.h"
#import "MediaPlayer.h"
@class uexVideoRecorder;
@class uexVideoMediaPlayer;

@interface EUExVideo : EUExBase {
	MediaPlayer *mPlayerObj;
}

@property (nonatomic,strong)uexVideoRecorder *recorder;
@property (nonatomic,strong)uexVideoMediaPlayer *player;
-(void)uexVideoWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData;


- (void)callbackJSONWithName:(NSString *)name object:(id)obj;

@end
