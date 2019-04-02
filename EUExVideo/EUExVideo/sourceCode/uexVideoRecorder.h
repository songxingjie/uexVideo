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
    uexVideoRecorderResolution1920x1080 = 0,
    uexVideoRecorderResolution1280x720,
    uexVideoRecorderResolution640x480,
    
    
};

typedef NS_ENUM(NSInteger,uexVideoRecorderBitRateLevel) {
    uexVideoRecorderBitRateLevelHigh = 0,
    uexVideoRecorderBitRateLevelMedium,
    uexVideoRecorderBitRateLevelLow,
};

typedef NS_ENUM(NSInteger,uexVideoRecorderOutputFileType) {
    uexVideoRecorderOutputFileTypeMP4,
    uexVideoRecorderOutputFileTypeMOV
};

@interface uexVideoRecorder : NSObject
@property (nonatomic,assign)NSTimeInterval maxDuration;
@property (nonatomic,assign)uexVideoRecorderResolution resolution;
@property (nonatomic,assign)uexVideoRecorderOutputFileType fileType;
@property (nonatomic,assign)uexVideoRecorderBitRateLevel bitRateLevel;
@property (nonatomic,assign)BOOL isCameraFront;//判断是否是前置摄像还是后置，默认为后置


- (instancetype)initWithEUExVideo:(EUExVideo *)euexObj;
- (void)statRecord;

@end
