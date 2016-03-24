/**
 *
 *	@file   	: uexVideoHelper.h  in EUExVideo Project .
 *
 *	@author 	: CeriNo.
 * 
 *	@date   	: Created on 16/3/15.
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
#import "EUtility.h"



#define SCREEN_W ([UIScreen mainScreen].bounds.size.width)//屏幕宽
#define SCREEN_H ([UIScreen mainScreen].bounds.size.height)//屏幕高
#define UEX_VIDEO_IMAGE_NAMED(name) _UEX_VIDEO_IMAGE_NAMED(name)//bundle中的image




#pragma mark - private macro

#define _UEX_VIDEO_BUNDLE ([EUtility bundleForPlugin:@"uexVideo"])
#define _UEX_VIDEO_BUNDLE_IMAGE_PATH(name,ext) ([[_UEX_VIDEO_BUNDLE resourcePath]stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.%@",name,ext]])//这里不能用pathForResource 否则2x 3x会有问题
#define _UEX_VIDEO_IMAGE_NAMED(name) ([UIImage imageWithContentsOfFile:_UEX_VIDEO_BUNDLE_IMAGE_PATH(name,@"png")])


extern NSString *const kUexVideoOrientationKey;
extern NSString *const kUexVideoVolumeKey;

@interface uexVideoHelper : NSObject

+ (NSString *)getSecretStringByKey:(NSString *)key;
+ (NSString *)stringFromSeconds:(NSInteger)seconds;


@end
