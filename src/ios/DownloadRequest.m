//
//  DownloadRequest.m
//  NYPRNative
//
//  Created by Brad Kammin on 4/16/13.
//
//

#import "ASINetworkQueue.h"

#import "DownloadRequest.h"

@implementation DownloadRequest


- (void)cancel
{
    NSLog(@"DownloadRequest--cancel");
    
    UIApplicationState appState=[UIApplication sharedApplication].applicationState;
    NSLog(@"Application State: %d", appState);
    if(appState==UIApplicationStateBackground){
        NSLog(@"App running in background");
    } else if(appState==UIApplicationStateInactive){
        NSLog(@"App inactive");
    } else if(appState==UIApplicationStateActive){
        NSLog(@"App running in foreground");
    } else {
        NSLog(@"App state unknown");
    }
    
    NSTimeInterval timeLeft = [UIApplication sharedApplication].backgroundTimeRemaining;
    NSInteger tl = timeLeft;
    NSLog(@"Background time remaining: %d seconds", tl );
    
    // if time left is less than ten seconds, and running the background assume this
    // request is being canceled due to timeout, and re-queue
    if(appState==UIApplicationStateBackground /*&& tl < 10*/){
        NSLog(@"requeueing due to background timeout");
        
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
