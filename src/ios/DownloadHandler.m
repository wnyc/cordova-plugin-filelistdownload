//
//  DownloadFile.m
//  NYPRNativeFeatures
//
//  Created by Brad Kammin on 11/28/12.
//
//

#import "DownloadHandler.h"

#import "ASINetworkQueue.h"
#import "DownloadRequest.h"

@implementation DownloadHandler

#define MINIMUM_MB 5
#define MINIMUM_SPACE (MINIMUM_MB * 1024 * 1024)


- (void)dealloc
{
    mCurrentJSON=nil;
    mNetworkQueue=nil;
    //[mCurrentJSON release];
    //	[mNetworkQueue release];
    //	[super dealloc];
}

-(void) scanPlaylist:(NSArray *)filelist{
    [self scanForDownloadedFiles:filelist];
}

-(void) downloadPlaylist:(NSArray *)filelist{

    BOOL restart=true;
    NSString * filename=nil;
    NSString * url=nil;;
    
    // test code
    //[self fillDiskSpace];
    
    // check if download is in progress
    if(mNetworkQueue != nil && [[self mNetworkQueue] requestsCount] > 0){
        NSLog(@"Download is in progress");
        
        // compare currently downloading JSON
        if([mCurrentJSON isEqualToArray:filelist]){
            // same JSON - continue download
            NSLog(@"JSON is the same -- continue");
            // scan for completed files -- the purpose of this is to notify the interface of file progress for completed files
            [self scanForDownloadedFiles:filelist];
            // cancel restart
            restart=false;
        }else{
            // stop the current download
            NSLog(@"JSON is different -- cancel current download and restart");
            [[self mNetworkQueue] cancelAllOperations];
        }
    }
    
    if (restart){
        // create a copy of the incoming file list
        // [mCurrentJSON release];
        mCurrentJSON=nil;
        mCurrentJSON = [[NSArray alloc] initWithArray:filelist copyItems:TRUE];
        
        // Stop anything already in the queue before removing it
        [[self mNetworkQueue] cancelAllOperations];
        
        // purge files not in playlist(s). do this prior to download to ensure maximum capacity.
        NSMutableSet * filesAlreadyHere = [self purgeOrphanFiles:filelist];
        
        // create a new queue -- so we don't have to worry about clearing delegates or resetting progress tracking
        [self setMNetworkQueue:[ASINetworkQueue queue]];
    
        // set self as delegate so it can receive 'selector' calls
        [[self mNetworkQueue] setDelegate:self];

        // show accurate progress - progress will be based on total download size, but has the overhead of making
        // a HEAD requeat for each GET request so it can determine download size before transfer starts...
        // but if this is turned off, the progress is updated only after each request is completed...
        //[[self mNetworkQueue] setShowAccurateProgress:YES];
    
        // this causes setProgress to be called with periodic progresss updates
        //[[self mNetworkQueue] setDownloadProgressDelegate:self];
    
        // set selector delegates
        [[self mNetworkQueue] setRequestDidReceiveResponseHeadersSelector:@selector(requestDidReceiveResponseHeaders:responseHeaders:)];
        [[self mNetworkQueue] setRequestDidStartSelector:@selector(requestStarted:)];
        [[self mNetworkQueue] setRequestDidFinishSelector:@selector(requestFinished:)];
        [[self mNetworkQueue] setRequestDidFailSelector:@selector(requestFailed:)];
        [[self mNetworkQueue] setQueueDidFinishSelector:@selector(queueFinished:)];
        
        [[self mNetworkQueue] setShouldCancelAllRequestsOnFailure:NO];
        
        [[self mNetworkQueue] setMaxConcurrentOperationCount:1];
    
        // add files to the queue
        for(int i=0;i<[filelist count];i++){
            NSDictionary * dict = [filelist objectAtIndex:i];
            url = [dict objectForKey:@"audio"];
            
            // check to see if file is already here
            if(url != nil){
                filename = [[[NSURL URLWithString:url] lastPathComponent] lowercaseString];
                if([filesAlreadyHere member:filename]==false){
                    // check to ensure minimum memory threshold is met
                    if([self minimumSpaceIsAvailable:MINIMUM_SPACE]){
                        [self addFileToQueue:filename url:url priority:NSOperationQueuePriorityNormal];
                    }else{
                        // fire an error notification
                        NSString * msg = [NSString stringWithFormat:@"Less than %dMB available on device", MINIMUM_MB];
                        [self notifyError:filename code:NYPRNativeInsufficientDiskSpaceType description:msg];
                    }
                }else{
                    NSLog(@"Skipping download, file already on device. File #%d. Url=%@", (i+1), url);
                    // fire event notifying of 'completed' download
                    [self notifyProgressUpdate:[url lastPathComponent] progress:1];
                }
            }else{
                // fire an error notification
                if(url==nil){
                    url=@"(null)";
                }
                if(filename==nil){
                    filename=@"(null)";
                }
                NSString * msg = [NSString stringWithFormat:@"Invalid audio Url: %@", url];
                [self notifyError:filename code:NYPRNativeInvalidURL description:msg];
            }
        }
    
        //[filesAlreadyHere release];
        filesAlreadyHere=nil;

        if ([[self mNetworkQueue] requestsCount] > 0) {
            // launch the download
            [[self mNetworkQueue] go];
        }else{
            // signal completed download
            [self queueFinished:[self mNetworkQueue]];
        }
    }
}
 
- (void)notifyProgressUpdate:(NSString *)filename progress:(float)progress{
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSNumber numberWithFloat:progress], @"progress",
                          filename, @"filename",
                          nil];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"DownloadProgressNotification"
     object:self
     userInfo:dict];
}

- (void)notifyError:(NSString *)filename code:(float)code description:(NSString *)description{
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                          filename, @"filename",
                          [NSNumber numberWithInteger:code], @"code",
                          description, @"description",
                          nil];
    
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"DownloadErrorNotification"
     object:self
     userInfo:dict];
}

- (void)request:(ASIHTTPRequest *)request didReceiveBytes:(long long)bytes; 
{
    float bytesRead =  (float)[request totalBytesRead];
    float bytesTotal = [request contentLength];
    NSString *filename = [[[request originalURL] absoluteString] lastPathComponent];
    float progress = bytesRead / bytesTotal;
    
    //NSLog(@"Data Recieved--%f. URL-%@", progress, filename);
    
    [self notifyProgressUpdate:filename progress:progress];
    
    NSTimeInterval timeLeft = [UIApplication sharedApplication].backgroundTimeRemaining;
    NSInteger tl = timeLeft;
    static NSInteger lastDisplayed;
    if (tl%10==0 ) {
        lastDisplayed = tl;
        NSLog(@"Background time remaining: %.0ld seconds", (long)lastDisplayed );
    }
}

- (void)request:(ASIHTTPRequest *)request incrementDownloadSizeBy:(long long)newLength
{
     //NSLog(@"Increment download size by--%lld. URL-%@", newLength, [request originalURL]);
}

- (void)requestStarted:(ASIHTTPRequest *)request
{
    NSString *filename = [[[request originalURL] lastPathComponent] lowercaseString];
    if(!filename){
        filename = [[[request url] lastPathComponent] lowercaseString];
    }
    
	//NSLog(@"Request started--%@; Length=%lld", [request url], [request contentLength]);
    // check to ensure minimum memory threshold is met
    if([self minimumSpaceIsAvailable:MINIMUM_SPACE]==FALSE){
        
        // fire an error notification
        NSString * msg = [NSString stringWithFormat:@"Less than %dMB available on device", MINIMUM_MB];
        [self notifyError:filename code:NYPRNativeInsufficientDiskSpaceType description:msg];
        
        [request cancel]; // handle the cancel
    }else{
        NSLog(@"Request started: %@ (Priority %d)", filename, [request queuePriority]);
    }
}

- (void)requestDidReceiveResponseHeaders:(ASIHTTPRequest *)request responseHeaders:(NSDictionary *)responseHeaders
{
	//NSLog(@"Request received response headers--%@; Length=%lld", [request url], [request contentLength]);
    
    // check to ensure minimum memory threshold is met
    if([self minimumSpaceIsAvailable:[request contentLength]]==FALSE){
        
        // fire an error notification
        NSString *filename = [[[request originalURL] lastPathComponent] lowercaseString];
        if(!filename){
            filename = [[[request url] lastPathComponent] lowercaseString];
        }
        NSString * msg = @"Not enough space for file on device";
        [self notifyError:filename code:NYPRNativeInsufficientDiskSpaceType description:msg];
        
        [request cancel];
    }
}

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSString *filename = [[[request originalURL] lastPathComponent] lowercaseString];
    if(!filename){
        filename = [[[request url] lastPathComponent] lowercaseString];
    }
    
    NSLog(@"Request finished -- %@", filename );
    
    NSError *error;
    NSString * dlDirectoryAndFilename = [NSString stringWithFormat:@"%@.download", [self getDownloadFileDestination:filename]];
    NSString * directoryAndFilename = [NSString stringWithFormat:@"%@", [self getDownloadFileDestination:filename]];
    
    // Attempt the move
    if ([[NSFileManager defaultManager] moveItemAtPath:dlDirectoryAndFilename toPath:directoryAndFilename error:&error] != YES){
        NSLog(@"Unable to move file: %@", [error localizedDescription]);
        // remove temporary download file
        [[NSFileManager defaultManager] removeItemAtPath:dlDirectoryAndFilename error:&error];
    } else {
        // don't back up to Cloud
        [self _addSkipBackupAttributeToItemAtURL:[NSURL fileURLWithPath:directoryAndFilename]];
    }
    
    // release the queue
    if ([[self mNetworkQueue] requestsCount] == 0) {
		[self setMNetworkQueue:nil];
	}
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error = [request error];
    NSString * description = [error description];
    int code = [error code];
    NSString *filename = [[[request originalURL] lastPathComponent] lowercaseString];
    if(!filename){
        filename = [[[request url] lastPathComponent] lowercaseString];
    }
    
    NSLog(@"Download Error - requestFailed - %@ (Code=%d)", [error description], code );
    
    if(code == ASIFileManagementError){
        // check disk space in an effort to determine cause of cancellation
        if([self minimumSpaceIsAvailable:[request contentLength]]==FALSE){
            code=NYPRNativeInsufficientDiskSpaceType;
            description = @"Not enough space for file on device";
        }
    }else if(code == ASIRequestCancelledErrorType){
        if([self minimumSpaceIsAvailable:MINIMUM_MB]==FALSE){
            code=NYPRNativeInsufficientDiskSpaceType;
            description = [NSString stringWithFormat:@"Less than %dMB available on device", MINIMUM_MB];
        }else if([self minimumSpaceIsAvailable:[request contentLength]]==FALSE){
            code=NYPRNativeInsufficientDiskSpaceType;
            description = @"Not enough space for file on device";
        }else{
            // in the event of a background timeout, requeue?
            //[self addFileToQueue:filename url:[[request originalURL] absoluteString] priority:NSOperationQueuePriorityHigh];
            
            description=@"The request was canceled";
        }
        
    }else{
        NSLog(@"Unknown error: %d %@ %@", [error code], filename, description );
    }
    
    
    
    [self notifyError:filename code:code description:description];

    // release the queue
    if ([[self mNetworkQueue] requestsCount] == 0) {
		[self setMNetworkQueue:nil];
	}
}

- (void)queueFinished:(ASINetworkQueue *)queue
{
	NSLog(@"Queue finished - Download Complete");
    
    // broadcast completion message
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"DownloadCompleteNotification"
     object:self
     ];
    
    // release the queue
    if ([[self mNetworkQueue] requestsCount] == 0) {
		[self setMNetworkQueue:nil];
	}
}

// Utility functions

- (NSString*)getDownloadDirectory{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [NSString stringWithFormat:@"%@/Audio/",documentsDirectory];
    return path;
}


- (NSString*)getDownloadFileDestination:(NSString *)file{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSError *error = nil;
    
    // create directory if it doesn't exist
    BOOL isDirectory;
    if (!([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"%@/Audio",documentsDirectory] isDirectory:&isDirectory] && isDirectory))
    {
        NSLog(@"Audio Directory Doesn't Exist - Create");
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/Audio",documentsDirectory] withIntermediateDirectories:YES attributes:nil error:&error])
            NSLog(@"Error: Create folder failed");
    }
    
    NSString *onlyFileName = [[[NSURL URLWithString:file] lastPathComponent] lowercaseString];
    NSString *fileName = [NSString stringWithFormat:@"%@/Audio/%@",documentsDirectory,onlyFileName];
    
    return fileName;
}


-(void) scanForDownloadedFiles:(NSArray *)filelist {
    NSString * filename;
    NSDictionary * dict;
    
    for(int i=0;i<[filelist count];i++){
        dict = [filelist objectAtIndex:i];
        filename = [self getDownloadFileDestination:[dict objectForKey:@"audio"]];
        NSString * shortFilename = [[dict objectForKey:@"audio"] lastPathComponent];
        if([[NSFileManager defaultManager] fileExistsAtPath:filename]){
            //filename=[[[dict objectForKey:@"audio"] lastPathComponent] lowercaseString];
            [self notifyProgressUpdate:shortFilename progress:1];
        } else {
            // notify progress 0
            //filename=[[[dict objectForKey:@"audio"] lastPathComponent] lowercaseString];
            [self notifyProgressUpdate:shortFilename progress:0];
            // there will be an incorrect 0% for the file that is currently being downloaded, until that download reports a progress change
            // is there a way here to look up the download status for this file and report it?
        }
    }
}

-(NSMutableSet *) purgeOrphanFiles:(NSArray *)filelist{
    
    NSMutableSet * filesToKeep =[[NSMutableSet alloc] init];
    NSMutableSet * filesAlreadyHere =[[NSMutableSet alloc] init];
    NSString * filename;
    NSString * directoryAndFilename;
    NSString * directory;
    NSDictionary * dict;
    int progress;
    NSError * error;
    BOOL force;
   
    // build a hash of files for quick lookup and notify interface of file progress
    for(int i=0;i<[filelist count];i++){
        dict = [filelist objectAtIndex:i];
        filename=[[[NSURL URLWithString:[dict objectForKey:@"audio"]] lastPathComponent] lowercaseString];
        force=[[dict objectForKey:@"force"] boolValue];
        if(!force){
            if(filename != nil) {
                [filesToKeep addObject:filename];
            } else {
                NSLog(@"Empty filename - not adding to download queue");
            }
        } else {
            NSLog(@"Force download of %@", filename);
        }
        directoryAndFilename = [self getDownloadFileDestination:filename];
        if([[NSFileManager defaultManager] fileExistsAtPath:directoryAndFilename]){
            if( !force ) {
                progress=1;
            } else {
                progress=0;
            }
        }else{
            progress=0;
        }
        [self notifyProgressUpdate:[[dict objectForKey:@"audio"] lastPathComponent] progress:progress];
    }
    
    // check each existing file. if not in current download list, then purge
    directory = [self getDownloadDirectory];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    if (files != nil) {
        for (NSString *file in files) {
            if([filesToKeep member:[file lowercaseString]] ){
                // file in list of files to keep - mark as 'already here'
                [filesAlreadyHere addObject:file];
            }else{
                // file not in list of files to keep - purge
                directoryAndFilename = [directory stringByAppendingPathComponent:file];
                [[NSFileManager defaultManager] removeItemAtPath:directoryAndFilename error:&error];
            }
        }
    }
    
    //[filesToKeep release];
    filesToKeep=nil;
    return filesAlreadyHere;
}


- (BOOL)minimumSpaceIsAvailable:(unsigned long long) neededSize {
    unsigned long long availableSize=0;
    NSError *error = nil;
    NSString * directory = [self getDownloadDirectory];
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:directory error: &error];
    
    if (dictionary) {
        NSNumber *fileSystemFreeSizeInBytes = [dictionary objectForKey: NSFileSystemFreeSize];
        availableSize = [fileSystemFreeSizeInBytes unsignedLongLongValue];
    }
    
    return (availableSize > neededSize);
}

- (void)fillDiskSpace{
    NSString * sourceDir = [self getDownloadDirectory];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    int counter=1;
    BOOL success=TRUE;
    NSError *error = nil;
    
    while([self minimumSpaceIsAvailable:MINIMUM_SPACE] && success==TRUE){
        NSString *destDir = [NSString stringWithFormat:@"%@/filler%d/",documentsDirectory,counter];
        counter++;
        success = [[NSFileManager defaultManager] copyItemAtPath:sourceDir toPath:destDir error:&error];
        if(success != YES) NSLog(@"Error: %@", error);
    }

}

- (void) addFileToQueue:(NSString *)filename url:(NSString*)url priority:(NSOperationQueuePriority)priority{
    NSLog(@"Queueing: %@", filename);
    NSString * directoryAndFilename = [NSString stringWithFormat:@"%@.download", [self getDownloadFileDestination:filename]];
    DownloadRequest *request = [DownloadRequest requestWithURL:[NSURL URLWithString:url]];
    [request setQueue:[self mNetworkQueue]];
    [request setQueuePriority:priority];
    [request setDownloadProgressDelegate:self];
    [request setNumberOfTimesToRetryOnTimeout:3];
    [request setShouldCompressRequestBody:TRUE];
    [request setDownloadDestinationPath:directoryAndFilename];
    [request setShouldContinueWhenAppEntersBackground:YES];
    [[self mNetworkQueue] addOperation:request];
    // placement of this line matters - putting it before addOperation will cancel it out -- addOperations assigns the showAccurateProgress flag from the queue
    // to the request
    [request setShowAccurateProgress:YES];
}

// prevent backup to the Cloud
- (BOOL)_addSkipBackupAttributeToItemAtURL:(NSURL *)URL{
    BOOL success=false;
    if ([[NSFileManager defaultManager] fileExistsAtPath: [URL path]])  {
        NSError *error = nil;
        success = [URL setResourceValue: [NSNumber numberWithBool: YES] forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!success){
            NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
        }
    }
    return success;
}

@synthesize mNetworkQueue;
@end
