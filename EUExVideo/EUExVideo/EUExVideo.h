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


@interface EUExVideo : EUExBase {
	MediaPlayer *mPlayerObj;
}
-(void)uexVideoWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData;
-(void)uexVideoWithFunction:(NSString *)name result:(NSString *)result;
@end
