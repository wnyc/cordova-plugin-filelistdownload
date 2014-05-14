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
    
        [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(_onDownloadProgress:) name:@"DownloadProgressNotification" object:nil];
        [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(_onDownloadComplete:) name:@"DownloadCompleteNotification" object:nil];
        [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(_onDownloadError:) name:@"DownloadErrorNotification" object:nil];
    
    }
}
    
#pragma mark Cleanup

- (void)dispose {
    NSLog(@"FileListDownload Plugin disposing");
    
    self->mDownloadHandler=nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadProgressNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadCompleteNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DownloadErrorNotification" object:nil];
    
    [super dispose];
}


#pragma mark Plugin handler

-(void)_sendPluginResult:(CDVPluginResult*)result callbackId:(NSString*)callbackId{
    if (_callbackId==nil){
        _callbackId=callbackId;
    }

    if (_callbackId!=nil) {
      [result setKeepCallbackAsBool:YES]; // keep for later callbacks
      [self.commandDelegate sendPluginResult:result callbackId:_callbackId];
    }
}

#pragma mark Download commands

- (void)scanfilelist:(CDVInvokedUrlCommand*)command
{
    NSLog (@"FileListDownload Plugin scanning file list.");
    
    if(command.arguments){
        [self _createDownloadHandler];
    
        if (_callbackId==nil) {
          _callbackId=command.callbackId;
        }

        [self->mDownloadHandler scanPlaylist:command.arguments];

        [self _sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    }else{
        [self _sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no arguments found"] callbackId:command.callbackId];
    }
}

- (void)downloadfilelist:(CDVInvokedUrlCommand*)command
{
    NSLog (@"FileListDownload Plugin downloading file list.");
    
    if(command.arguments){
        [self _createDownloadHandler];

        if (_callbackId==nil) {
          _callbackId=command.callbackId;
        }

        [self->mDownloadHandler downloadPlaylist:command.arguments];

        [self _sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];
    }else{
        [self _sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"no arguments found"] callbackId:command.callbackId];
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
        
        NSDictionary * o = @{ @"type" : @"progress",
                              @"percent" : [NSNumber numberWithInt:(int)progress],
                              @"filename" : filename};
        
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:o];
        [self _sendPluginResult:pluginResult callbackId:_callbackId];
    }
}

- (void) _onDownloadComplete:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DownloadCompleteNotification"]){
        NSDictionary * o = @{ @"type" : @"complete" };
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:o];
        [self _sendPluginResult:pluginResult callbackId:_callbackId];
    }
}

- (void) _onDownloadError:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:@"DownloadErrorNotification"]){
        
        NSDictionary *dict = [notification userInfo];
        
        NSString * filename = [dict objectForKey:(@"filename")];
        int code = [[dict  objectForKey:(@"code")] intValue];
        NSString * description= [dict objectForKey:(@"description")];

        NSDictionary * o = @{ @"type" : @"error", @"code" : [NSNumber numberWithInt:code], @"description" : description, @"filename" : filename};
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:o];
        [self _sendPluginResult:pluginResult callbackId:_callbackId];

    }
}

@end
