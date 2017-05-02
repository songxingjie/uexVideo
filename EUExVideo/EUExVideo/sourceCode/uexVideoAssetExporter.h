/**
 *
 *	@file   	: uexVideoAssetExporter.h  in EUExVideo Project .
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
#import <AVFoundation/AVFoundation.h>


@interface uexVideoAssetExporter : NSObject



@property (nonatomic,strong) AVAsset *asset;

@property (nonatomic,strong) NSString *outputFileType;
@property (nonatomic,strong) NSURL *outputURL;
@property (nonatomic,strong) NSDictionary *videoInputSettings;
@property (nonatomic,strong) NSDictionary *videoSettings;
@property (nonatomic,strong) NSDictionary *audioSettings;
@property (nonatomic,assign) CMTimeRange timeRange;
- (instancetype)initWithAsset:(AVAsset *)asset;

- (RACSignal *)startExportSignal;

- (void)cancel;



@end
