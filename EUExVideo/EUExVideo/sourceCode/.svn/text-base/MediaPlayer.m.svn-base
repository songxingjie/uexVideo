//
//  mediaPlayer.m
//  WebKitCorePlam
//
//  Created by AppCan on 11-9-9.
//  Copyright 2011 AppCan. All rights reserved.
//

#import "MediaPlayer.h"
#import "EUExVideo.h"
#import "EUtility.h"
#import "EUExBaseDefine.h"

@implementation MediaPlayer
//@synthesize euexObj;
-(void)initWithEuex:(EUExVideo *)euexObj_{
	euexObj = euexObj_;
}

-(void)open:(NSString*)inPath{

	NSURL *movieURL = nil;
	if ([inPath hasPrefix:@"http:"]) {// || [moviePath hasPrefix:@"rtsp:"]) {
        inPath = [inPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		movieURL = [NSURL URLWithString:inPath];
	}
	else {
		if (![[NSFileManager defaultManager] fileExistsAtPath:inPath]) {
			[euexObj jsFailedWithOpId:0 errorCode:1210102 errorDes:UEX_ERROR_DESCRIBE_FILE_EXIST];
			return;
		}
		movieURL = [NSURL fileURLWithPath:inPath];
	}
	if (movieURL&&[movieURL scheme])
	{
		PluginLog(@"movie start");
		if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 3.2){
			PluginLog(@"verson >3.2");
			MPMoviePlayerViewController *playerViewController = [[MPMoviePlayerViewController alloc] initWithContentURL:movieURL];  
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(myMovieViewFinishedCallback:)  
														 name:MPMoviePlayerPlaybackDidFinishNotification  
													   object:playerViewController];  
			
			[playerViewController.moviePlayer prepareToPlay];
			[playerViewController.moviePlayer play];
			[playerViewController.moviePlayer setFullscreen:YES];
            [EUtility brwView:euexObj.meBrwView presentModalViewController:playerViewController animated:YES];
			//[playerViewController release];
		}else {
			//如果系统版本在4.0以前，用下面这个
			MPMoviePlayerController *MPPlayer = [[MPMoviePlayerController alloc] initWithContentURL:movieURL];
			MPPlayer.scalingMode = MPMovieScalingModeAspectFill;
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(myMovieFinishedCallback:)
														 name:MPMoviePlayerPlaybackDidFinishNotification
													   object:MPPlayer];
			[MPPlayer play];
 		}
	}else{
		[euexObj jsFailedWithOpId:0 errorCode:1210103 errorDes:UEX_ERROR_DESCRIBE_FILE_FORMAT];
	}
}
 
-(void)myMovieFinishedCallback:(NSNotification*)aNotification
{
	PluginLog(@"run 1 callback");
	MPMoviePlayerController* theMovie=[aNotification object];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie];
	[theMovie release]; 
}
-(void)myMovieViewFinishedCallback:(NSNotification*)aNotification {
	PluginLog(@"run 2 callback");
	MPMoviePlayerViewController* theMovieView=[aNotification object];
	[theMovieView dismissMoviePlayerViewControllerAnimated];
	[[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovieView];
	[theMovieView release];
	[[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
}
-(void)dealloc{
	[super dealloc];
}
@end
