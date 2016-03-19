/**
 *
 *	@file   	: uexVideoPlayerMaskView.h  in EUExVideo Project .
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
@class uexVideoPlayerView;
@interface uexVideoPlayerMaskView : UIView

//以下signal均没有side effects
@property (nonatomic,strong)RACSignal *playButtonClickSignal;//play按钮点击事件
@property (nonatomic,strong)RACSignal *fullScreenButtonClickSignal;//全屏按钮点击事件
@property (nonatomic,strong)RACSignal *progressSliderValueChangeSignal;//slider滑动中progress的变化
@property (nonatomic,strong)RACSignal *progressSliderStartDraggingSignal;//slider的滑动事件 当开始滑动时sendNext:@YES ,结束滑动时sendNext:@NO

- (instancetype)initWithPlayerView:(uexVideoPlayerView *)playerView;

- (void)setFullScreenButtonHidden:(BOOL)isHidden;
- (void)setShowViewSignal:(RACSignal *)signal;


@end




