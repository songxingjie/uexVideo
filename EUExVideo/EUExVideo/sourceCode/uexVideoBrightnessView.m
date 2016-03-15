/**
 *
 *	@file   	: uexVideoBrightnessView.m  in EUExVideo Project .
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

#import "uexVideoBrightnessView.h"

@interface uexVideoBrightnessView()
@property (nonatomic,strong)UIView *progressView;
@property (nonatomic,assign)BOOL isEnabled;
@end

@implementation uexVideoBrightnessView

+ (instancetype)sharedView{
    static uexVideoBrightnessView *view = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        view = [[self alloc] init];
        
    });
    return view;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        
        self.backgroundColor = [EUtility colorFromHTMLString:@"9A9A9ACD"];
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        [window addSubview:self];
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(window);
            
        }];
    }
    return self;
}

- (void)enable{
    self.isEnabled = YES;
}
- (void)disable{
    self.isEnabled = NO;
}
@end
