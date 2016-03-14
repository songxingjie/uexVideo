//
//  RecordVideo.h
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>

@class EUExVideo;
@interface RecordVideo : NSObject <UIImagePickerControllerDelegate,UINavigationControllerDelegate>{
	EUExVideo *euexObj;
}
//@property(nonatomic, retain)EUExVideo *euexObj;;
-(void)initWithEuex:(EUExVideo *)euexObj_;
-(void)openVideoRecord:(float)maxDuration qualityType:(NSInteger)qualityType compressRatio:(float)compressRatio fileType:(NSString *)fileType;

@property(nonatomic ,assign)float compressRatio;
@property(nonatomic ,assign)NSInteger fileLength;
@property(nonatomic ,assign)NSString *fileType;
@property(nonatomic ,strong)AVAssetExportSession *session;
@end
