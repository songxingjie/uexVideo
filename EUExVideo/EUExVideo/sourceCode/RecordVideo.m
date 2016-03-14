//
//  RecordVideo.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//


#import "RecordVideo.h"
#import "EUtility.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "EUExVideo.h"
#import "EUExBaseDefine.h"

@implementation RecordVideo
//@synthesize euexObj;

-(void)initWithEuex:(EUExVideo *)euexObj_ {
    euexObj = euexObj_;
}
-(NSString*)getSavename:(NSString*)type{
	NSFileManager *filemag = [NSFileManager defaultManager];
    NSString *wgtPath = [euexObj absPath:@"wgt://"];
	NSString *videoPath = [wgtPath stringByAppendingPathComponent:@"video"];
	if (![filemag fileExistsAtPath:videoPath]) {
		[filemag createDirectoryAtPath:videoPath withIntermediateDirectories:YES attributes:nil error:nil];
	}
	NSString *filepath_cfg = [videoPath stringByAppendingPathComponent:@"movieCfg.cfg"];
	NSString *maxNum = [NSString stringWithContentsOfFile:filepath_cfg encoding:NSUTF8StringEncoding error:nil];
	int max = 0;
	NSString *saveName;
	if (maxNum) {
		max = [maxNum intValue];
		if (max==9999) {
			max = 0;
		}
		else {
			max++;
		}
		NSString *currentMax = [NSString stringWithFormat:@"%d",max];
		[currentMax writeToFile:filepath_cfg atomically:YES encoding:NSUTF8StringEncoding error:nil];
	} else {
		NSString *currentMax = @"0";
		[currentMax writeToFile:filepath_cfg atomically:YES encoding:NSUTF8StringEncoding error:nil];
	}
	
    NSString *fileType=self.fileType;
    if (max<10&max>=0) {
        saveName = [NSString stringWithFormat:@"movie_000%d.%@", max, fileType];
    }
    else if (max<100&max>=10) {
        saveName = [NSString stringWithFormat:@"movie_00%d.%@",max, fileType];
    }
    else if (max<1000&max>=100) {
        saveName = [NSString stringWithFormat:@"movie_0%d.%@",max, fileType];
    }
    else if (max<10000&max>=1000) {
        saveName = [NSString stringWithFormat:@"movie_%d.%@",max, fileType];
    }
    else {
        saveName = [NSString stringWithFormat:@"movie_0000.%@", fileType];
    }
	NSString *resPath = [videoPath stringByAppendingPathComponent:saveName];
	return resPath;
}
-(void)openVideoRecord:(float)maxDuration qualityType:(NSInteger)qualityType compressRatio:(float)compressRatio fileType:(NSString *)fileType{
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
		picker.delegate = self;
        //		[picker setAllowsImageEditing:YES];
        if(maxDuration>0){
            picker.videoMaximumDuration=maxDuration;
        }
        switch (qualityType) {
            case 0:
                picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
                break;
            case 1:
                picker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
                break;
            case 2:
                picker.videoQuality = UIImagePickerControllerQualityTypeIFrame960x540;
                break;
            case 3:
                picker.videoQuality = UIImagePickerControllerQualityType640x480;
                break;
                
            default:
                break;
        }
        self.fileType=fileType;
        self.compressRatio=compressRatio;
		picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [EUtility brwView:euexObj.meBrwView presentModalViewController:picker animated:YES];
	}
}
////不压缩
//-(void)saveMovie:(NSData *)movData{
//    NSError *error;
//    NSFileManager *fmanager = [NSFileManager defaultManager];
//    NSString *moviePath = [self getSavename:@"movie"];
//    if([fmanager fileExistsAtPath:moviePath]) {
//        [fmanager removeItemAtPath:moviePath error:&error];
//    }
//    
//    BOOL success = [movData writeToFile:moviePath atomically:YES];
//    if (success) {
//        [euexObj uexVideoWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:moviePath];
//    }else {
//        [euexObj jsFailedWithOpId:0 errorCode:1210205 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
//    }
//}
-(void)saveMovie:(NSURL *)inputURL{
	NSError *error;
    NSFileManager *fmanager = [NSFileManager defaultManager];
    NSString *moviePath = [self getSavename:@"MP4"];
 	if([fmanager fileExistsAtPath:moviePath]) {
		[fmanager removeItemAtPath:moviePath error:&error];
	}
    //系统压缩
    [self lowQuailtyWithInputURL:inputURL outputURL:[NSURL fileURLWithPath:moviePath] blockHandler:^(AVAssetExportSession *session)
     {
        switch (session.status) {
            case AVAssetExportSessionStatusUnknown:
                NSLog(@"AVAssetExportSessionStatusUnknown");
                break;
            case AVAssetExportSessionStatusWaiting:
                NSLog(@"AVAssetExportSessionStatusWaiting");
                break;
            case AVAssetExportSessionStatusExporting:
                NSLog(@"AVAssetExportSessionStatusExporting");
                break;
            case AVAssetExportSessionStatusCancelled:
                NSLog(@"AVAssetExportSessionStatusCancelled");
                break;
            case AVAssetExportSessionStatusCompleted:
                [euexObj uexVideoWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:moviePath];
                NSLog(@"------------%f",[self getFileSize:moviePath]);
                break;
            case AVAssetExportSessionStatusFailed:
                [euexObj jsFailedWithOpId:0 errorCode:1210205 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
                break;
        }
    }];
}

//系统压缩
- (void) lowQuailtyWithInputURL:(NSURL*)inputURL
                      outputURL:(NSURL*)outputURL
                   blockHandler:(void (^)(AVAssetExportSession*))handler
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    self.session = [[AVAssetExportSession alloc] initWithAsset:asset     presetName:AVAssetExportPresetHighestQuality];
    self.session.outputURL = outputURL;
    self.session.outputFileType = AVFileTypeMPEG4;
    if([self.fileType isEqual:@"MOV"]){
        self.session.outputFileType = AVFileTypeQuickTimeMovie;
    }
    if(self.compressRatio>0 && self.compressRatio<1){
        self.session.fileLengthLimit=self.fileLength*self.compressRatio;
    }
    NSTimer * timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(onExportWithProgress:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop]addTimer:timer forMode:NSDefaultRunLoopMode];
    //[timer fire];
    
    [self.session exportAsynchronouslyWithCompletionHandler:^(void)
     {
         [timer invalidate];
         handler(self.session);
     }];
}
-(void)onExportWithProgress:(NSTimer *)timer{
    //NSLog(@"-----------------progress::%f",self.session.progress);
    [euexObj uexVideoWithFunction:@"onExportWithProgress" result:[@{@"progress":@(self.session.progress) } JSONFragment]];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
	if([mediaType isEqualToString:@"public.movie"]){
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
        self.fileLength=videoData.length;
        NSLog(@"=================%lu",videoData.length/1024);
        [self performSelector:@selector(saveMovie:) withObject:videoURL afterDelay:0];
	}
    [picker dismissModalViewControllerAnimated:YES];
}
- (CGFloat) getFileSize:(NSString *)path{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    float filesize = -1.0;
    if ([fileManager fileExistsAtPath:path]) {
        NSDictionary *fileDic = [fileManager attributesOfItemAtPath:path error:nil];//获取文件的属性
        unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
        filesize = 1.0*size/1024;
    }
    return filesize;
}

@end
