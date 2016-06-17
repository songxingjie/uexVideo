
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

-(void)initWithEuex:(EUExVideo *)euexObj{
    _euexObj = euexObj;
}

-(void)open:(NSString*)inPath{
    
    NSURL *movieURL = nil;
    if ([inPath hasPrefix:@"http:"]) {
        inPath = [inPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        movieURL = [NSURL URLWithString:inPath];
    }
    else {
        if (![[NSFileManager defaultManager] fileExistsAtPath:inPath]) {
            //[_euexObj jsFailedWithOpId:0 errorCode:1210102 errorDes:UEX_ERROR_DESCRIBE_FILE_EXIST];
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
            [[self.euexObj.webViewEngine viewController]presentViewController:playerViewController animated:YES completion:nil];

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
        //[_euexObj jsFailedWithOpId:0 errorCode:1210103 errorDes:UEX_ERROR_DESCRIBE_FILE_FORMAT];
    }
}

-(void)myMovieFinishedCallback:(NSNotification*)aNotification
{

    MPMoviePlayerController* theMovie=[aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovie];

}
-(void)myMovieViewFinishedCallback:(NSNotification*)aNotification {

    MPMoviePlayerViewController* theMovieView=[aNotification object];
    [theMovieView dismissMoviePlayerViewControllerAnimated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:theMovieView];

    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
}

@end
