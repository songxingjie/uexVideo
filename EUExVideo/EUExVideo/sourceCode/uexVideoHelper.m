/**
 *
 *	@file   	: uexVideoHelper.m  in EUExVideo Project .
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

#import "uexVideoHelper.h"
#import <CommonCrypto/CommonCrypto.h>

NSString *const kUexVideoOrientationKey = @"LEqsLyC3MJ5Vh90gxGLxdg==";
NSString *const kUexVideoVolumeKey = @"MAHEkBLJkIPJwueEYYz9PQ==";

@implementation uexVideoHelper


+ (NSString *)stringFromSeconds:(NSInteger)seconds{
    NSString *min = [NSString stringWithFormat:@"%02ld",(long)(seconds / 60)];
    NSString *sec = [NSString stringWithFormat:@"%02ld",(long)(seconds % 60)];
    return [NSString stringWithFormat:@"%@:%@", min, sec];
}

+ (NSString *)getSecretStringByKey:(NSString *)key{
    NSData *data = [[NSData alloc]initWithBase64EncodedString:key options:0];
    char keyPtr[kCCKeySizeAES256+1];
    bzero(keyPtr, sizeof(keyPtr));
    NSString *k = @"appcan";
    [k getCString:keyPtr maxLength:sizeof(keyPtr) encoding:NSUTF8StringEncoding];
    NSUInteger dataLength = [data length];
    size_t bufferSize = dataLength + kCCBlockSizeAES128;
    void *buffer = malloc(bufferSize);
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt,
                                          kCCAlgorithmAES128,
                                          kCCOptionPKCS7Padding,
                                          keyPtr,
                                          kCCKeySizeAES256,
                                          NULL,
                                          [data bytes],
                                          dataLength,
                                          buffer,
                                          bufferSize,
                                          &numBytesDecrypted);
    NSString *result = @"";
    if (cryptStatus == kCCSuccess) {
        NSData *resultData = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted freeWhenDone:NO];
        result = [[NSString alloc]initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    free(buffer);
    return result;
}



@end
