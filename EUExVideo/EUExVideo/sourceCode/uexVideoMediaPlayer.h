/**
 *
 *	@file   	: uexVideoMediaPlayer.h  in EUExVideo Project .
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

@class EUExVideo;
@interface uexVideoMediaPlayer : NSObject 
@property (nonatomic,assign)BOOL isScrollWithWeb;
@property (nonatomic,assign)BOOL autoStart;
@property (nonatomic,assign)BOOL forceFullScreen;
@property (nonatomic,assign)BOOL showCloseButton;
@property (nonatomic,assign)BOOL showScaleButton;
-(instancetype)initWithEUExVideo:(EUExVideo *)euexObj;

- (void)openWithFrame:(CGRect)frame path:(NSString *)inPath startTime:(CGFloat)startTime;

- (void)close;
@end
