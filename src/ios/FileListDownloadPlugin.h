//
//  FileListDownload.h
//  NYPRNative
//
//  Created by Bradford Kammin on 4/2/14.
//
//

#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVPluginResult.h>

#import "DownloadHandler.h"

@interface FileListDownloadPlugin : CDVPlugin
{
    DownloadHandler     * mDownloadHandler;
    
    NSString * _callbackId;
}

- (void)downloadfilelist:(CDVInvokedUrlCommand*)command;
- (void)scanfilelist:(CDVInvokedUrlCommand*)command;

@end
