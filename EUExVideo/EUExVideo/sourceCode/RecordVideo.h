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
@interface RecordVideo : NSObject <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic, weak)EUExVideo *euexObj;



-(instancetype)initWithEuex:(EUExVideo *)euexObj;

-(void)openVideoRecord:(float)maxDuration qualityType:(NSInteger)qualityType compressRatio:(float)compressRatio fileType:(NSString *)fileType;

@property(nonatomic ,assign)CGFloat compressRatio;
@property(nonatomic ,assign)NSInteger fileLength;
@property(nonatomic ,assign)NSString *fileType;
//@property(nonatomic ,strong)AVAssetExportSession *session;
@end
