//
//  DownloadRequest.m
//  NYPRNative
//
//  Created by Brad Kammin on 4/16/13.
//
//

#import "ASINetworkQueue.h"
#import "DownloadRequest.h"
#import "DDLog.h"

extern int ddLogLevel;

@implementation DownloadRequest


- (void)cancel {
    DDLogInfo(@"FileListDownload Plugi DownloadRequest--cancel");
    
    UIApplicationState appState=[UIApplication sharedApplication].applicationState;
    DDLogInfo(@"FileListDownload Plugin Application State: %ld", appState);
    if(appState==UIApplicationStateBackground){
        DDLogInfo(@"FileListDownload Plugin App running in background");
    } else if(appState==UIApplicationStateInactive){
        DDLogInfo(@"FileListDownload Plugin App inactive");
    } else if(appState==UIApplicationStateActive){
        DDLogInfo(@"FileListDownload Plugin App running in foreground");
    } else {
        DDLogInfo(@"FileListDownload Plugin App state unknown");
    }
    
    NSTimeInterval timeLeft = [UIApplication sharedApplication].backgroundTimeRemaining;
    NSInteger tl = timeLeft;
    DDLogInfo(@"FileListDownload Plugin Background time remaining: %ld seconds", (long)tl );
    
    // if time left is less than ten seconds, and running the background assume this
    // request is being canceled due to timeout, and re-queue
    if(appState==UIApplicationStateBackground /*&& tl < 10*/){
        DDLogInfo(@"FileListDownload Plugin requeueing due to background timeout");
        
        ASINetworkQueue * q = [self queue];
        
        DownloadRequest *newRequest = [DownloadRequest requestWithURL:[self originalURL]];
        [newRequest setQueue:q];
        [newRequest setQueuePriority:NSOperationQueuePriorityHigh];
        [newRequest setDownloadProgressDelegate:[self downloadProgressDelegate]];
        [newRequest setNumberOfTimesToRetryOnTimeout:3];
        [newRequest setShouldCompressRequestBody:TRUE];
        [newRequest setDownloadDestinationPath:[self downloadDestinationPath]];
        [newRequest setShouldContinueWhenAppEntersBackground:YES];
        [q addOperation:newRequest];
        // placement of this line matters - putting it before addOperation will cancel it out -- addOperations assigns the showAccurateProgress flag from the queue
        // to the request
        [newRequest setShowAccurateProgress:YES];
    }
    
    [super cancel];
}

@end
