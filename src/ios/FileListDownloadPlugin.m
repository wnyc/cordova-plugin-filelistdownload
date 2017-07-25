//
//  FileListDownload.m
//  NYPRNative
//
//  Created by Bradford Kammin on 4/2/14.
//
//

#import "FileListDownloadPlugin.h"
#import "DDLog.h"

extern int ddLogLevel;

@interface FileListDownloadPlugin ()

@property (nonatomic) NSString *userAgent;

@end

@implementation FileListDownloadPlugin

#pragma mark Initialization

- (void) _createDownloadHandler {
    if(self->mDownloadHandler==nil){
        DDLogInfo(@"FileListDownload Plugin creating handler.");
        
        self->mDownloadHandler=[[DownloadHandler alloc] init];
        if (self.userAgent) {
            self->mDownloadHandler.userAgent = self.userAgent;
        }
    
        [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(_onDownloadProgress:) name:@"DownloadProgressNotification" object:nil];
        [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(_onDownloadComplete:) name:@"DownloadCompleteNotification" object:nil];
        [[NSNotificationCenter defaultCenter]   addObserver:self selector:@selector(_onDownloadError:) name:@"DownloadErrorNotification" object:nil];
    
    }
}
    
#pragma mark Cleanup

- (void)dispose {
    DDLogInfo(@"FileListDownload Plugin disposing");
    
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

- (void)scanfilelist:(CDVInvokedUrlCommand*)command {
    DDLogInfo(@"FileListDownload Plugin scanning file list.");
    
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
    DDLogInfo(@"FileListDownload Plugin downloading file list.");
    
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

- (void) _onDownloadProgress:(NSNotification *) notification {
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

- (void) _onDownloadComplete:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"DownloadCompleteNotification"]){
        NSDictionary * o = @{ @"type" : @"complete" };
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:o];
        [self _sendPluginResult:pluginResult callbackId:_callbackId];
    }
}

- (void) _onDownloadError:(NSNotification *) notification {
    if ([[notification name] isEqualToString:@"DownloadErrorNotification"]){
        
        NSDictionary *dict = [notification userInfo];
        
        NSString * filename = [dict objectForKey:(@"filename")];
        int code = [[dict  objectForKey:(@"code")] intValue];
        NSString * description= [dict objectForKey:(@"description")];

        if (!filename) {
          filename=@"";
        }

        if (!description) {
          description=@"";
        }

        NSDictionary * o = @{ @"type" : @"error", @"code" : [NSNumber numberWithInt:code], @"description" : description, @"filename" : filename};
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:o];
        [self _sendPluginResult:pluginResult callbackId:_callbackId];

    }
}


- (void)setuseragent:(CDVInvokedUrlCommand*)command {
    DDLogInfo (@"FileListDownload Plugin configuring user agent");

    CDVPluginResult* pluginResult = nil;

    if (command.arguments.count>0 && [command.arguments objectAtIndex:0] != (id)[NSNull null]) {
        self.userAgent = [command.arguments objectAtIndex:0];
        if (self->mDownloadHandler) {
            self->mDownloadHandler.userAgent = self.userAgent;
        }
    }

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    [self _sendPluginResult:pluginResult callbackId:_callbackId];
}

@end
