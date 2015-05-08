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
		[rVideoObj release];
		rVideoObj = nil;
	}
    if (mPlayerObj) {
		[mPlayerObj release];
		mPlayerObj = nil;
	}
	[super dealloc];
}

-(void)open:(NSMutableArray *)inArguments {
	NSString *inPath = [inArguments objectAtIndex:0];
	if (inPath) {
		mPlayerObj = [[MediaPlayer alloc] init];
		[mPlayerObj initWithEuex:self];
		NSString *absPath = [super absPath:inPath];
		[mPlayerObj open:absPath];
	}else {
		[self jsFailedWithOpId:0 errorCode:1210101 errorDes:UEX_ERROR_DESCRIBE_ARGS];
	}
}

-(void)record:(NSMutableArray *)inArguments {
	rVideoObj = [[RecordVideo alloc] init];
	[rVideoObj initWithEuex:self];
	[rVideoObj openVideoRecord];
}

-(void)uexVideoWithOpId:(int)inOpId dataType:(int)inDataType data:(NSString *)inData{
	if (inData) {
		[self jsSuccessWithName:@"uexVideo.cbRecord" opId:inOpId dataType:inDataType strData:inData];
	}
}

-(void)clean{
	if (rVideoObj) {
		[rVideoObj release];
		rVideoObj = nil;
	}
    if (mPlayerObj) {
		[mPlayerObj release];
		mPlayerObj = nil;
	}
}

@end
