//
//  FileListDownload.m
//  NYPRNative
//
//  Created by Bradford Kammin on 4/2/14.
//
//

#import "FileListDownloadPlugin.h"

@implementation FileListDownloadPlugin

#pragma mark Initialization

- (void) _createDownloadHandler {
    if(self->mDownloadHandler==nil){
        NSLog (@"FileListDownload Plugin creating handler.");
        
        self->mDownloadHandler=[DownloadHandler alloc];
    
        [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(_onDownloadProgress:)
                                                   name:@"DownloadProgressNotification"
                                                 object:nil];
        [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(_onDownloadComplete:)
                                                   name:@"DownloadCompleteNotification"
                                                 object:nil];
    
        [[NSNotificationCenter defaultCenter]   addObserver:self
                                               selector:@selector(_onDownloadError:)
                                                   name:@"DownloadErrorNotification"
                                                 object:nil];
    
    }
}
    
#pragma mark Cleanup

- (void)dispose {
    NSLog(@"FileListDownload Plugin disposing");
    if(self->mDownloadHandler){
        //[self->mDownloadHandler release];
        self->mDownloadHandler=nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadProgressNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadCompleteNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadErrorNotification" object:nil];
    [super dispose];
}

#pragma mark Download commands

- (void)scanfilelist:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    NSLog (@"FileListDownload Plugin scanning file list.");
    
    if(command.arguments){
        [self _createDownloadHandler];
        [self->mDownloadHandler scanPlaylist:command.arguments];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }else{
        // return an error - no parameter
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void)downloadfilelist:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    
    NSLog (@"FileListDownload Plugin downloading file list.");
    
    if(command.arguments){
        [self _createDownloadHandler];
        [self->mDownloadHandler downloadPlaylist:command.arguments];
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }else{
        // return an error - no parameter
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


#pragma mark Downlaod event handlers

- (void) _onDownloadProgress:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DownloadProgressNotification"]){
        
        NSDictionary *dict = [notification userInfo];
        
        float progress = [[dict  objectForKey:(@"progress")] floatValue];
        NSString * filename = [dict objectForKey:(@"filename")];
        
        progress *= 100;
        
        NSString * jsToRun=[NSString stringWithFormat:@"NYPRNativeFeatures.prototype.DownloadProgress(%i, '%@')", (int) progress, filename];
        dispatch_async(dispatch_get_main_queue(), ^{
            // this runs the call to UIKit on the main thread. not doing so causes a crash.
            //NSLog(@"JS to run: %@", jsToRun);
            [self writeJavascript:jsToRun];
        });
    }
}

- (void) _onDownloadComplete:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DownloadCompleteNotification"]){
        NSString * jsToRun=[NSString stringWithFormat:@"NYPRNativeFeatures.prototype.DownloadComplete()"];
        dispatch_async(dispatch_get_main_queue(), ^{
            // this runs the call to UIKit on the main thread. not doing so causes a crash.
            //NSLog(@"JS to run: %@", jsToRun);
            [self writeJavascript:jsToRun];
        });
    }
}

- (void) _onDownloadError:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DownloadErrorNotification"]){
        
        NSDictionary *dict = [notification userInfo];
        
        NSString * filename = [dict objectForKey:(@"filename")];
        int code = [[dict  objectForKey:(@"code")] intValue];
        NSString * description= [dict objectForKey:(@"description")];
        
        NSString * jsToRun=[NSString stringWithFormat:@"NYPRNativeFeatures.prototype.DownloadError('%@', %i,'%@')", filename, code, description];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self writeJavascript:jsToRun];
        });
    }
}

@end
