/**
 *
 *	@file   	: uexVideoRecorder.h  in EUExVideo Project .
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

#import <Foundation/Foundation.h>
@class EUExVideo;

typedef NS_ENUM(NSInteger,uexVideoRecorderResolution) {
    uexVideoRecorderResolutionCustom = 0,
    uexVideoRecorderResolution640x480,
    uexVideoRecorderResolution1280x720,
    uexVideoRecorderResolution1920x1080,
};

typedef NS_ENUM(NSInteger,uexVideoRecorderOutputFileType) {
    uexVideoRecorderOutputFileTypeMP4,
    uexVideoRecorderOutputFileTypeMOV
};

@interface uexVideoRecorder : NSObject
@property (nonatomic,assign)NSTimeInterval maxDuration;
@property (nonatomic,assign)uexVideoRecorderResolution resolution;
@property (nonatomic,assign)CGFloat outputWidth;
@property (nonatomic,assign)CGFloat outputHeight;
@property (nonatomic,assign)CGFloat bitRateMultipier; //采样率为 outputWidth * outputHeight * bitRateMultipier
@property (nonatomic,assign)uexVideoRecorderOutputFileType fileType;
extern CGFloat uexVideoRecorderDefaultBitRateMultipier;//默认为 5.0


- (instancetype)initWithEUExVideo:(EUExVideo *)euexObj;

- (void)statRecord;

@end
