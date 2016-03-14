//
//  EUExVideoMgr.m
//  webKitCorePalm
//
//  Created by AppCan on 11-9-7.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "EUExVideo.h"

#import "EUtility.h"
#import "EUExBaseDefine.h"

@implementation EUExVideo

-(id)initWithBrwView:(EBrowserView *) eInBrwView{
	if (self = [super initWithBrwView:eInBrwView]) {
	}
	return self;
}

-(void)dealloc{
	if (rVideoObj) {
		//[rVideoObj release];
		rVideoObj = nil;
	}
    if (mPlayerObj) {
		//[mPlayerObj release];
		mPlayerObj = nil;
	}
	//[super dealloc];
}

-(void)open:(NSMutableArray *)inArguments {
    if(inArguments.count<1){
        return;
    }
	NSString *inPath = [inArguments objectAtIndex:0];
	if (inPath) {
		NSString *absPath = [super absPath:inPath];
        float startTime=0;
        int frequency=1;
        if(inArguments.count>1){
            id info=[inArguments[1] JSONValue];
            startTime=[[info objectForKey:@"startTime"] floatValue];
            if([[info objectForKey:@"frequency"] intValue]){
                frequency=[[info objectForKey:@"frequency"] intValue];
            }
        }
        mPlayerObj = [[MediaPlayer alloc] init];
        [mPlayerObj initWithEuex:self startTime:startTime frequency:frequency];
        [mPlayerObj open:absPath];
	}else {
		[self jsFailedWithOpId:0 errorCode:1210101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
	}
}

-(void)record:(NSMutableArray *)inArguments {
	rVideoObj = [[RecordVideo alloc] init];
	[rVideoObj initWithEuex:self];
    float maxDuration=0;
    NSInteger qualityType=0;
    float compressRatio=1;
    NSString *fileType=@"MP4";
    if(inArguments.count>0){
        id info=[inArguments[0] JSONValue];
        if([info objectForKey:@"maxDuration"]){
            maxDuration=[[info objectForKey:@"maxDuration"] floatValue];
        }
        if([info objectForKey:@"qualityType"]){
            qualityType=[[info objectForKey:@"qualityType"] integerValue];
        }
        if([info objectForKey:@"compressRatio"]){
            compressRatio=[[info objectForKey:@"compressRatio"] floatValue];
        }
        if([info objectForKey:@"fileType"]){
            if ([[info objectForKey:@"fileType"] isEqual:@"MOV"]) {
                fileType = @"MOV";
            }
        }
    }
    [rVideoObj openVideoRecord:maxDuration qualityType:qualityType compressRatio:compressRatio fileType:fileType];
}
-(void)uexVideoWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData{
	if (inData) {
        NSString *cbStr=[NSString stringWithFormat:@"if(uexVideo.cbRecord != null){uexVideo.cbRecord(%d,%d,'%@');}",inOpId,inDataType,inData];
        [EUtility brwView:meBrwView evaluateScript:cbStr];
	}
}
-(void)uexVideoWithFunction:(NSString *)name result:(NSString *)result{
    if(![result isKindOfClass:[NSString class]]){
        result=[result JSONFragment];
    }
    NSString *cbStr=[NSString stringWithFormat:@"if(uexVideo.%@ != null){uexVideo.%@('%@');}",name,name,result];
    [EUtility brwView:meBrwView evaluateScript:cbStr];
}

-(void)clean{
	if (rVideoObj) {
		rVideoObj = nil;
	}
    if (mPlayerObj) {
		mPlayerObj = nil;
	}
}

@end
