/**
 *
 *	@file   	: uexVideoRecorder.m  in EUExVideo Project .
 *
 *	@author 	: CeriNo.
 * 
 *	@date   	: Created on 16/3/14.
 *
 *	@copyright 	: 2016 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "uexVideoRecorder.h"
#import "uexVideoAssetExporter.h"
#import "EUExVideo.h"
#import "EUtility.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
@interface uexVideoRecorder()<UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic,assign)CGFloat outputWidth;
@property (nonatomic,assign)CGFloat outputHeight;
@property (nonatomic,weak)EUExVideo *euexObj;
@property (nonatomic,strong)uexVideoAssetExporter *exporter;

@end;

@implementation uexVideoRecorder


- (instancetype)initWithEUExVideo:(EUExVideo *)euexObj{
    self = [super init];
    if (self) {
        _euexObj = euexObj;
        _fileType = uexVideoRecorderOutputFileTypeMP4;
        _outputWidth = 1920;
        _outputHeight = 1080;
        _resolution = uexVideoRecorderResolution1920x1080;
        _bitRateLevel = uexVideoRecorderBitRateLevelHigh;
    }
    return self;
}


- (NSString *)makeSavePath{
    NSString *saveFolder = [self.euexObj absPath:@"wgt://video"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:saveFolder]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:saveFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSDate *date = [[NSDate alloc]initWithTimeIntervalSinceNow:0];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMdd_HH_mm_ss"];
    NSString *dateStr = [dateFormatter stringFromDate:date];
    NSString *ext;
    switch (self.fileType) {
        case uexVideoRecorderOutputFileTypeMP4:{
            ext = @"mp4";
            break;
        }
        case uexVideoRecorderOutputFileTypeMOV:{
            ext = @"mov";
            break;
        }
    }
    return [saveFolder stringByAppendingPathComponent:[NSString stringWithFormat:@"movie_%@.%@",dateStr,ext]];
    
}

- (void)statRecord{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        NSDictionary *dict = @{
                               @"result":@(2),
                               @"errorStr":@"camera unavailable"
                               };
        
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onRecordFinish" arguments:ACArgsPack(dict.ac_JSONFragment)];
        return;
    }
    
    
    
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    
    if (self.maxDuration > 0) {
        picker.videoMaximumDuration = self.maxDuration;
    }
    
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    picker.delegate = self;
    picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    picker.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    switch (self.resolution) {
        case uexVideoRecorderResolution640x480: {
            picker.videoQuality = UIImagePickerControllerQualityType640x480;
            self.outputWidth = 640;
            self.outputHeight = 480;
            break;
        }
        case uexVideoRecorderResolution1280x720: {
            picker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
            self.outputWidth = 1280;
            self.outputHeight = 720;
            break;
        }
        case uexVideoRecorderResolution1920x1080: {
            picker.videoQuality = UIImagePickerControllerQualityTypeHigh;
            self.outputWidth = 1920;
            self.outputHeight = 1080;
            break;
        }
    }
    
    
    
    picker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
    
    UIViewController *controller = [self.euexObj.webViewEngine viewController];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }

    
    
    
     [[self requestRecordRequest]subscribeError:^(NSError *error) {
         
         NSDictionary *dict = @{
                                @"result":@(2),
                                @"errorStr":@"request access failed."
                                };
         
         [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onRecordFinish" arguments:ACArgsPack(dict.ac_JSONFragment)];
         
     } completed:^{
         dispatch_async(dispatch_get_main_queue(), ^{
             [controller presentViewController:picker animated:YES completion:nil];
         });
     }];
     


}


- (RACSignal *)requestRecordRequest{
    
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if(granted){
                [subscriber sendCompleted];
            }else{
                [subscriber sendError:nil];
            }
        }];
        return nil;
    }]then:^RACSignal *{
        return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
                if(granted){
                    [subscriber sendCompleted];
                }else{
                    [subscriber sendError:nil];
                }
            }];
            return nil;
        }];
    }];
}





#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{
            NSDictionary *dict = @{@"result":@(1)};
            [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onRecordFinish" arguments:ACArgsPack(dict.ac_JSONFragment)];

            self.euexObj.recorder = nil;
        }];
    });
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    if([mediaType isEqualToString:@"public.movie"]){
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        AVAsset *asset = [AVURLAsset assetWithURL:videoURL];
        [self exportMovieWithAsset:asset];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{
            self.euexObj.recorder = nil;
        }];
    });

}

- (void)exportMovieWithAsset:(AVAsset *)asset{
    if (!asset) {
        return;
    }
    uexVideoAssetExporter *exporter = [[uexVideoAssetExporter alloc]initWithAsset:asset];
    [self resetExporter];
    self.exporter = exporter;
    switch (self.fileType) {
        case uexVideoRecorderOutputFileTypeMP4: {
            exporter.outputFileType = AVFileTypeMPEG4;
            break;
        }
        case uexVideoRecorderOutputFileTypeMOV: {
            exporter.outputFileType = AVFileTypeQuickTimeMovie;
            break;
        }
    }

    exporter.videoSettings = @{
                               AVVideoCodecKey: AVVideoCodecH264,
                               AVVideoWidthKey: @(self.outputWidth),
                               AVVideoHeightKey: @(self.outputHeight),
                               AVVideoCompressionPropertiesKey: @{
                                       AVVideoAverageBitRateKey: [self bitRateDict][@(self.resolution)][@(self.bitRateLevel)] ?: @(5000000),
                                       AVVideoProfileLevelKey: AVVideoProfileLevelH264High40,
                                       },
                               };
    exporter.audioSettings = @{
                               AVFormatIDKey: @(kAudioFormatMPEG4AAC),
                               AVNumberOfChannelsKey: @2,
                               AVSampleRateKey: @44100,
                               AVEncoderBitRateKey: @128000,
    };
    NSString *savePath = [self makeSavePath];
    exporter.outputURL = [NSURL fileURLWithPath:savePath];
    [exporter.startExportSignal subscribeNext:^(NSNumber *progress) {
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onExportWithProgress" arguments:ACArgsPack(progress)];
    } error:^(NSError *error) {
        ACLogWarning(@"%@",error.localizedDescription);
        NSDictionary *dict = @{
                               @"result":@(2),
                               @"errorStr":error.localizedDescription
                               };
        
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onRecordFinish" arguments:ACArgsPack(dict.ac_JSONFragment)];
    } completed:^{

        /*
        CGFloat fileSize = -1.0;
        if ([[NSFileManager defaultManager] fileExistsAtPath:savePath]) {
            NSDictionary *fileDic = [[NSFileManager defaultManager] attributesOfItemAtPath:savePath error:nil];
            unsigned long long size = [[fileDic objectForKey:NSFileSize] longLongValue];
            fileSize = 1.0*size/1024;
        }
        NSLog(@"complete! fileSize : %@",@(fileSize));
         */
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.cbRecord" arguments:ACArgsPack(@0,@0,savePath)];
        NSDictionary *dict = @{
                               @"result":@(0),
                               @"path":savePath
                               };
        
        [self.euexObj.webViewEngine callbackWithFunctionKeyPath:@"uexVideo.onRecordFinish" arguments:ACArgsPack(dict.ac_JSONFragment)];
    }];
}

- (NSDictionary *)bitRateDict{
    return @{
             @(uexVideoRecorderResolution1920x1080):@{
                     @(uexVideoRecorderBitRateLevelHigh):@8000000,
                     @(uexVideoRecorderBitRateLevelMedium):@5600000,
                     @(uexVideoRecorderBitRateLevelLow):@2400000,
                     },
             @(uexVideoRecorderResolution1280x720):@{
                     @(uexVideoRecorderBitRateLevelHigh):@5000000,
                     @(uexVideoRecorderBitRateLevelMedium):@3500000,
                     @(uexVideoRecorderBitRateLevelLow):@1500000,
                     },
             @(uexVideoRecorderResolution640x480):@{
                     @(uexVideoRecorderBitRateLevelHigh):@2500000,
                     @(uexVideoRecorderBitRateLevelMedium):@1750000,
                     @(uexVideoRecorderBitRateLevelLow):@750000,
                     },
             };
}
- (void)resetExporter{
    if (self.exporter) {
        [self.exporter cancel];
        self.exporter = nil;
    }
}

- (void)dealloc{
    [self resetExporter];
}

@end
