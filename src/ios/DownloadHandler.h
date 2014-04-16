//
//  DownloadFile.h
//  NYPRNativeFeatures
//
//  Created by Brad Kammin on 11/28/12.
//
//

#import <Foundation/Foundation.h>

typedef enum _NYPRNativeDownloadErrorType {
    NYPRNativeInsufficientDiskSpaceType = 101,
    NYPRNativeInvalidURL = 102
	
} NYPRNativeDownloadErrorType;

@class ASINetworkQueue;

@interface DownloadHandler : NSObject
{    
    ASINetworkQueue *mNetworkQueue;
    NSArray * mCurrentJSON;
}

@property (retain) ASINetworkQueue *mNetworkQueue;

-(void) downloadPlaylist:(NSArray*)filelist;
-(void) scanPlaylist:(NSArray*)filelist;
-(NSString *)getDownloadDirectory;

@end
