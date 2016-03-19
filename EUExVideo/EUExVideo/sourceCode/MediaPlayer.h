//
//  mediaPlayer.h
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
@class EUExVideo;
@interface MediaPlayer : NSObject <MPMediaPickerControllerDelegate>

@property (nonatomic,weak)EUExVideo *euexObj;
-(void)open:(NSString*)inPath;
-(void)initWithEuex:(EUExVideo *)euexObj;
@end
