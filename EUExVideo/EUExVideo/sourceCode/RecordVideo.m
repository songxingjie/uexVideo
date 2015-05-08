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
	
	NSString *fileType;
	if ([type isEqualToString:@"movie"]) {
		fileType = @"MOV";
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
    }
	NSString *resPath = [videoPath stringByAppendingPathComponent:saveName];
	return resPath;
}
-(void)openVideoRecord{
	UIImagePickerController *picker = [[UIImagePickerController alloc] init];
	if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
		picker.mediaTypes = [NSArray arrayWithObject:(NSString *)kUTTypeMovie];
		picker.delegate = self;
        //		[picker setAllowsImageEditing:YES];
		picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
		picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [EUtility brwView:euexObj.meBrwView presentModalViewController:picker animated:YES];
		[picker release];
	}
}
-(void)saveMovie:(NSData *)movData{
	NSError *error;
    NSFileManager *fmanager = [NSFileManager defaultManager];
    NSString *moviePath = [self getSavename:@"movie"];
 	if([fmanager fileExistsAtPath:moviePath]) {
		[fmanager removeItemAtPath:moviePath error:&error];
	}
	
	BOOL success = [movData writeToFile:moviePath atomically:YES];
    if (success) {
        [euexObj uexVideoWithOpId:0 dataType:UEX_CALLBACK_DATATYPE_TEXT data:moviePath];
    }else {
        [euexObj jsFailedWithOpId:0 errorCode:1210205 errorDes:UEX_ERROR_DESCRIBE_FILE_SAVE];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
	if([mediaType isEqualToString:@"public.movie"]){
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSData *videoData = [NSData dataWithContentsOfURL:videoURL];
        [self performSelector:@selector(saveMovie:) withObject:videoData afterDelay:0];
	}
    [picker dismissModalViewControllerAnimated:YES];
}

-(void)dealloc{
	[super dealloc];
    //    [euexObj release];
}
@end
