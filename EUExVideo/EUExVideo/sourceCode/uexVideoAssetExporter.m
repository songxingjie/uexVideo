/**
 *
 *	@file   	: uexVideoAssetExporter.m  in EUExVideo Project .
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

#import "uexVideoAssetExporter.h"
@interface uexVideoAssetExporter()

@property (nonatomic,strong) AVAssetReader *reader;
@property (nonatomic,strong) AVAssetReaderVideoCompositionOutput *videoOutput;
@property (nonatomic,strong) AVAssetReaderAudioMixOutput *audioOutput;
@property (nonatomic,strong) AVAssetWriter *writer;
@property (nonatomic,strong) AVAssetWriterInput *videoInput;
@property (nonatomic,strong) AVAssetWriterInputPixelBufferAdaptor *videoPixelBufferAdaptor;
@property (nonatomic,strong) AVAssetWriterInput *audioInput;
@property (nonatomic,assign) NSTimeInterval duration;
@property (nonatomic,strong) dispatch_queue_t inputQueue;

@property (nonatomic,strong) RACSubject *cancelSignal;

@property (nonatomic,assign) BOOL needExportVideo;
@property (nonatomic,assign) BOOL needExportAudio;
@property (nonatomic,assign) __block CMTime endTime;



@end



@implementation uexVideoAssetExporter


- (instancetype)initWithAsset:(AVAsset *)asset
{
    self = [super init];
    if (self) {
        _asset = asset;
        _timeRange = CMTimeRangeMake(kCMTimeZero, kCMTimePositiveInfinity);
        _cancelSignal = [RACSubject subject];
        [self reset];
        
    }
    return self;
}

- (void)reset{
    self.reader = nil;
    self.videoOutput = nil;
    self.audioOutput = nil;
    self.writer = nil;
    self.videoInput = nil;
    self.videoPixelBufferAdaptor = nil;
    self.audioInput = nil;
    self.inputQueue = nil;
    self.needExportAudio = YES;
    self.needExportVideo = YES;
    self.endTime = kCMTimeZero;
}

- (void)cancel{
    [self.cancelSignal sendNext:nil];
}


- (RACSignal *)startExportSignal{
    [self cancel];
    NSError *error = [self checkReadyError];
    if (error) {
        return [RACSignal error:error];
    }
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        @weakify(self);
        [self.cancelSignal subscribeNext:^(id x) {
            @strongify(self);
            [self.writer cancelWriting];
            [self.reader cancelReading];
            [subscriber sendError:[NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@{NSLocalizedDescriptionKey: @"Exportation has been Cancelled!" }]];
        }];
        self.reader.timeRange = self.timeRange;
        self.writer.shouldOptimizeForNetworkUse = YES;
        if (CMTIME_IS_VALID(self.timeRange.duration) && !CMTIME_IS_POSITIVE_INFINITY(self.timeRange.duration)){
            self.duration = CMTimeGetSeconds(self.timeRange.duration);
        }else{
            self.duration = CMTimeGetSeconds(self.asset.duration);
        }
        
        [self setupVideoSettingsWithVideoTracks:[self.asset tracksWithMediaType:AVMediaTypeVideo]];
        [self setupAudioSettingsWithAudioTracks:[self.asset tracksWithMediaType:AVMediaTypeAudio]];
        [self.writer startWriting];
        [self.reader startReading];
        [self.writer startSessionAtSourceTime:self.timeRange.start];
        self.inputQueue = dispatch_queue_create("uexVideoAssetExporterInputQueue", DISPATCH_QUEUE_SERIAL);
        RACSignal *audioEncodingSignal = [self encodingSignalFromOutput:self.audioOutput toInput:self.audioInput needEncode:self.needExportAudio].distinctUntilChanged;
        RACSignal *videoEncodingSignal = [self encodingSignalFromOutput:self.videoOutput toInput:self.videoInput needEncode:self.needExportVideo].distinctUntilChanged;
        [[RACSignal combineLatest:@[audioEncodingSignal,videoEncodingSignal] reduce:^id(NSNumber *audioProgress,NSNumber *videoProgress){
            return @(fmin(audioProgress.doubleValue, videoProgress.doubleValue));
        }]subscribeNext:^(NSNumber *progress) {
            [subscriber sendNext:progress];
        } completed:^{
            [self.writer endSessionAtSourceTime:self.endTime];
            [self.writer finishWritingWithCompletionHandler:^{
                [subscriber sendCompleted];
            }];
            
        }];
        return [RACDisposable disposableWithBlock:^{
            if (self.writer.status == AVAssetWriterStatusFailed || self.writer.status == AVAssetWriterStatusCancelled){
                [NSFileManager.defaultManager removeItemAtURL:self.outputURL error:nil];
            }
            [self reset];
        }];
    }];

}

- (NSError *)checkReadyError{
    if (!self.outputURL) {
        return [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@{NSLocalizedDescriptionKey: @"Output URL not set" }];
    }
    if (!self.outputFileType) {
        return [NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@{NSLocalizedDescriptionKey: @"Output FileType not set"}];
    }
    NSError *error = nil;
    self.reader = [[AVAssetReader alloc]initWithAsset:self.asset error:&error];
    if (error) {
        return error;
    }
    self.writer = [[AVAssetWriter alloc]initWithURL:self.outputURL fileType:self.outputFileType error:&error];
    if (error) {
        return error;
    }
    return nil;
}

- (void)setupVideoSettingsWithVideoTracks:(NSArray<AVAssetTrack *> *)videoTracks{
    if (videoTracks.count > 0) {
        AVAssetTrack *videoTrack = videoTracks[0];
        CGAffineTransform transform = videoTrack.preferredTransform;
        CGFloat videoAngleInDegree  = atan2(transform.b, transform.a) * 180 / M_PI;
        if (fabs(videoAngleInDegree) == 90) {
            //竖屏录制的情况
            NSMutableDictionary *settings = [self.videoSettings mutableCopy];
            CGFloat width = [settings[AVVideoWidthKey] floatValue];
            [settings setValue:settings[AVVideoHeightKey] forKey:AVVideoWidthKey];
            [settings setValue:@(width) forKey:AVVideoHeightKey];
            self.videoSettings = settings;
        }
        
        
        self.videoOutput = [AVAssetReaderVideoCompositionOutput assetReaderVideoCompositionOutputWithVideoTracks:videoTracks videoSettings:self.videoInputSettings];
        self.videoOutput.alwaysCopiesSampleData = NO;
        self.videoOutput.videoComposition = [self makeVideoComposition];
        if ([self.reader canAddOutput:self.videoOutput]){
            [self.reader addOutput:self.videoOutput];
        }
        
        self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoSettings];
        self.videoInput.expectsMediaDataInRealTime = NO;
        if ([self.writer canAddInput:self.videoInput]){
            [self.writer addInput:self.videoInput];
        }
        NSDictionary *pixelBufferAttributes = @{
                                                (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
                                                (id)kCVPixelBufferWidthKey: @(self.videoOutput.videoComposition.renderSize.width),
                                                (id)kCVPixelBufferHeightKey: @(self.videoOutput.videoComposition.renderSize.height),
                                                @"IOSurfaceOpenGLESTextureCompatibility": @(YES),
                                                @"IOSurfaceOpenGLESFBOCompatibility": @(YES),
                                                };
        self.videoPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput sourcePixelBufferAttributes:pixelBufferAttributes];
    }else{
        self.needExportVideo = NO;
    }
}

- (void)setupAudioSettingsWithAudioTracks:(NSArray<AVAssetTrack *> *)audioTracks{
    if (audioTracks.count > 0) {
        self.audioOutput = [AVAssetReaderAudioMixOutput assetReaderAudioMixOutputWithAudioTracks:audioTracks audioSettings:nil];
        self.audioOutput.alwaysCopiesSampleData = NO;
        if ([self.reader canAddOutput:self.audioOutput]){
            [self.reader addOutput:self.audioOutput];
        }
    } else {
        self.audioOutput = nil;
    }
    
    if (self.audioOutput) {
        self.audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioSettings];
        self.audioInput.expectsMediaDataInRealTime = NO;
        if ([self.writer canAddInput:self.audioInput]) {
            [self.writer addInput:self.audioInput];
        }
    }else{
        self.needExportAudio = NO;
    }

}


- (AVMutableVideoComposition *)makeVideoComposition{
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    AVAssetTrack *videoTrack = [[self.asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    float trackFrameRate = 0;
    if (self.videoSettings){
        NSDictionary *videoCompressionProperties = [self.videoSettings objectForKey:AVVideoCompressionPropertiesKey];
        if (videoCompressionProperties){
            NSNumber *maxKeyFrameInterval = [videoCompressionProperties objectForKey:AVVideoMaxKeyFrameIntervalKey];
            if (maxKeyFrameInterval){
                trackFrameRate = maxKeyFrameInterval.floatValue;
            }
        }
    }else{
        trackFrameRate = [videoTrack nominalFrameRate];
    }
    
    if (trackFrameRate == 0){
        trackFrameRate = 30;
    }
    
    videoComposition.frameDuration = CMTimeMake(1, trackFrameRate);
    CGSize targetSize = CGSizeMake([self.videoSettings[AVVideoWidthKey] floatValue], [self.videoSettings[AVVideoHeightKey] floatValue]);
    CGSize naturalSize = [videoTrack naturalSize];
    CGAffineTransform transform = videoTrack.preferredTransform;
    CGFloat videoAngleInDegree  = atan2(transform.b, transform.a) * 180 / M_PI;
    if (videoAngleInDegree == 90 || videoAngleInDegree == -90) {
        CGFloat width = naturalSize.width;
        naturalSize.width = naturalSize.height;
        naturalSize.height = width;
    }
    videoComposition.renderSize = naturalSize;
    
    CGFloat ratio;
    CGFloat xratio = targetSize.width / naturalSize.width;
    CGFloat yratio = targetSize.height / naturalSize.height;
    ratio = MIN(xratio, yratio);
    
    CGFloat postWidth = naturalSize.width * ratio;
    CGFloat postHeight = naturalSize.height * ratio;
    CGFloat transx = (targetSize.width - postWidth) / 2;
    CGFloat transy = (targetSize.height - postHeight) / 2;
    
    CGAffineTransform matrix = CGAffineTransformMakeTranslation(transx / xratio, transy / yratio);
    matrix = CGAffineTransformScale(matrix, ratio / xratio, ratio / yratio);
    transform = CGAffineTransformConcat(transform, matrix);
    
    AVMutableVideoCompositionInstruction *passThroughInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    passThroughInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, self.asset.duration);
    AVMutableVideoCompositionLayerInstruction *passThroughLayer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [passThroughLayer setTransform:transform atTime:kCMTimeZero];
    passThroughInstruction.layerInstructions = @[passThroughLayer];
    videoComposition.instructions = @[passThroughInstruction];
    return videoComposition;
}

- (RACSignal *)encodingSignalFromOutput:(AVAssetReaderOutput *)output toInput:(AVAssetWriterInput *)input needEncode:(BOOL)needEncode{
    if (!needEncode) {
        return [RACSignal return:@1];
    }
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        __block CMTime lastSamplePresentationTime;
        [input requestMediaDataWhenReadyOnQueue:self.inputQueue usingBlock:^{
            while ([input isReadyForMoreMediaData]){
                CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer];
                if (sampleBuffer){
                    BOOL errorOccurred = NO;
                    if (self.reader.status != AVAssetReaderStatusReading || self.writer.status != AVAssetWriterStatusWriting){
                        errorOccurred = YES;
                    }
                    if (!errorOccurred && self.videoOutput == output){
                        lastSamplePresentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                        lastSamplePresentationTime = CMTimeSubtract(lastSamplePresentationTime, self.timeRange.start);
                        if (self.duration == 0) {
                            [subscriber sendNext:@1];
                        }else{
                            [subscriber sendNext:@(CMTimeGetSeconds(lastSamplePresentationTime) / self.duration)];
                        }
                    }
                    if (!errorOccurred && ![input appendSampleBuffer:sampleBuffer]){
                        errorOccurred = YES;
                    }
                    CFRelease(sampleBuffer);
                    if (errorOccurred){
                        [subscriber sendError:[NSError errorWithDomain:AVFoundationErrorDomain code:AVErrorExportFailed userInfo:@{NSLocalizedDescriptionKey: @"an Error occurred while encoding!" }]];
                        return;
                    }
                }else{
                    self.endTime = lastSamplePresentationTime;
                    [input markAsFinished];
                    [subscriber sendNext:@1];
                    [subscriber sendCompleted];
                    return;
                }
            }

        }];
        return nil;
    }];
}





@end
