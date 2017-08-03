package org.nypr.cordova.filelistdownloadplugin;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;

import android.content.Context;
//import android.media.MediaScannerConnection;
//import android.net.Uri;

import android.os.Environment;
import android.os.StatFs;
import android.util.Log;

public class DownloadMediaFileTask implements Runnable {
	
	protected static final String LOG_TAG = "DownloadMediaFileTask";
	
	protected static final int MINIMUM_MB = 5;
	protected static final int MINIMUM_SPACE = MINIMUM_MB * 1024 * 1024; // MB * KB/MB * B/KB
	
	private Context mContext;
	protected String mDestinationFile;
	protected String mDownloadUrl;
	protected OnDownloadUpdateListener mDownloadListener;
    protected String mUserAgent;
	
	private volatile boolean mCancel = false;
	
	private static final int SUCCESS = 0; 
	private static final int DOWNLOAD_FAILED = 1; 
	private static final int SDCARD_UNAVAILABLE = 2;
	private static final int CANCELED = 3; 
	
	public static final int NOT_DOWNLOADED = 0; 
	public static final int DOWNLOADED = 1; 
	public static final int QUEUED = 2; 
	public static final int DOWNLOADING = 3; 

	public DownloadMediaFileTask(){
	}
	
	public DownloadMediaFileTask(Context c, OnDownloadUpdateListener listener, String url, String userAgent) {
		try {
			this.mContext = c;
			this.mDownloadUrl=url;
			mDownloadListener=listener;
            mUserAgent=userAgent;
			this.mDestinationFile = new File(mDownloadUrl).getName();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public void run() {
		startDownload(mContext, mDownloadListener, mDownloadUrl, mDestinationFile, mUserAgent);
	}
	
	public void cancelFileDownload(){
		// set cancel flag, which is monitored by data download loop
		mCancel=true;
	}
	
	public void startDownload(Context context, OnDownloadUpdateListener listener, String sourceUrl, String destinationFile, String userAgent){
		String errorMessage="";
		int downloadStatus = 0;
		String progressFilename=null;
		URLConnection connection=null;
		InputStream input=null;
		FileOutputStream output=null;
		File file=null;
		
		try { 
			mCancel=false;
		
			if(destinationFile==null){
				 destinationFile = new File(sourceUrl).getName();
			}
		
			progressFilename=new File(sourceUrl).getName();
			progressFilename=Utilities.stripArgumentsFromFilename(progressFilename);
			
			Log.d(LOG_TAG, "Performing Download");
			Log.d(LOG_TAG, "Source URL\t:" + sourceUrl);
			Log.d(LOG_TAG, "Destination File\t:" + destinationFile);
					
			downloadStatus = SUCCESS; 
			if (sourceUrl == null || destinationFile==null || sourceUrl == "" || destinationFile=="") { 
				Log.d(LOG_TAG, "Failing due to file/url");
				errorMessage="Bad URL or filename";
				
				// this should be at end of function
				downloadStatus = DOWNLOAD_FAILED; 
				if(listener!=null){
					listener.onDownloadError(progressFilename, downloadStatus, errorMessage);
				}
				return; 
			}
			
			String path=getDirectory(context);
			
			// check for a minimum amount of available space before trying to download. this is to avoid
			// making a connection that will likely result in a file size that is too big to download...
			if(!minimumSpaceIsAvailable(path, MINIMUM_SPACE)){
	        	throw new IOException("Less than " + MINIMUM_MB + "MB available on device"); 
	        }
		
			// command line to view contents of music directory on emulator
			// adb shell "ls -al /mnt/sdcard/Android/data/org.nypr.phonegap.android.NYPRNative/files/Music/"
			
			if(path!=null){
				Log.d(LOG_TAG, "Initializing Download--" + progressFilename);
				
				// download the audio
			    int count;
		        URL url = new URL(sourceUrl);
		        connection = url.openConnection();		        
		        connection.setConnectTimeout(1000 * 15);
		        connection.setReadTimeout(1000 * 15);
                if (userAgent != null) {
                    connection.setRequestProperty("User-Agent", userAgent);
                }
		        
		        // this will be useful so that you can show a typical 0-100% progress bar
		        int lengthOfFile = connection.getContentLength();
		        
		        if(!minimumSpaceIsAvailable(path, lengthOfFile)){
		        	throw new IOException("Not enough space for file on device"); 
		        }

		        Log.d(LOG_TAG, "Connection Made. Length of File: " + lengthOfFile);
		        
		        // download the file
		        input = new BufferedInputStream(connection.getInputStream());
		        		        
				Log.d(LOG_TAG, "Writing File: " + (path + destinationFile + ".download"));
				
				file = new File(path + destinationFile + ".download");
				output = new FileOutputStream(file); // throws FileNotFoundException

		        byte data[] = new byte[1024];

		        long total = 0;

		        long oldP=0;
		        while (!mCancel && (count = input.read(data)) != -1) {
		            total += count;
		            // publishing the progress....
		            if((total*100/lengthOfFile)!=oldP){
		            	oldP=(total*100/lengthOfFile);
		            	if(oldP>100){
		            		oldP=100;
		            	}
		            	
		            	if(oldP % 10==0){
		            		Log.d(LOG_TAG, "Downloaded " + oldP + "% of " + progressFilename );
		            	}
		            	
						if(listener!=null){
							listener.onDownloadListProgressUpdate(progressFilename, (int)oldP);
						}
		            }
		            output.write(data, 0, count); // throws IOException
		        }

		        //Log.d(LOG_TAG, "Flushing and Closing Files");
		        output.flush(); // throws IOException
		        output.close(); // throws IOException
		        input.close();
		        
		        if(!mCancel){
			        // drop the .download extension
			        file.renameTo(new File(path + destinationFile));
			        downloadStatus = SUCCESS;
		        }else{
		        	Log.d(LOG_TAG, "File Download Canceled. Deleting temp file");
		        	file.delete();
		        	downloadStatus = CANCELED;
		        	errorMessage="File download canceled";
		        }

			    Log.d(LOG_TAG, "Download Completed--" + progressFilename); 
			}else { 
				downloadStatus = SDCARD_UNAVAILABLE; 
				errorMessage="External Storage Unavailable";
			}
		} catch (MalformedURLException e) { 
			downloadStatus = DOWNLOAD_FAILED; 
			errorMessage=e.getMessage();
			e.printStackTrace(); 
		} catch (IOException e) { 
			downloadStatus = DOWNLOAD_FAILED; 
			errorMessage=e.getMessage();
			cleanup( input, output, file );
			//e.printStackTrace(); 
		} catch (Exception e){
			downloadStatus = DOWNLOAD_FAILED; 
			errorMessage=e.getMessage();
			e.printStackTrace(); 
		} finally {
			if(downloadStatus==SUCCESS){
				if(listener!=null){
					// notify 100% downloaded...
					listener.onDownloadListProgressUpdate(progressFilename, 100);
				}
			}else{
				if(listener!=null){
					// notify of error
					// different event if canceled, or is CANCELED status sufficient?
					listener.onDownloadError(progressFilename, downloadStatus, errorMessage);
				}
			}
		}
		
	}

	protected void cleanup(InputStream input, FileOutputStream output, File file ){
		if(input!=null){
			try {
				input.close();
			} catch (Exception e) {
			} finally{
				input=null;
			}
		}
		
		if(output!=null){
			try {
				output.close();
			} catch (Exception e) {
				e.printStackTrace();
			}finally{
				output=null;
			}
		}
		
		if(file!=null){
			try {
				file.delete();
			} catch (Exception e) {
			} finally{
				file=null;
			}	
		}
	}
	
	public static String getDirectory(Context context){
		// one-stop for directory, so it only needs to be changed here once
		// check if we can write to the SDCard
		
		boolean externalStorageAvailable = false;
		boolean externalStorageWriteable = false;
		String state = Environment.getExternalStorageState();

		if (Environment.MEDIA_MOUNTED.equals(state)) {
		    // We can read and write the media
		    externalStorageAvailable = externalStorageWriteable = true;			    
		    //Log.d(LOG_TAG, "External Storage Available (Readable and Writeable)");
		} else if (Environment.MEDIA_MOUNTED_READ_ONLY.equals(state)) {
		    // We can only read the media
			externalStorageAvailable = true;
			externalStorageWriteable = false;				
			Log.d(LOG_TAG, "External Storage Read Only");
		} else {
		    // Something else is wrong. It may be one of many other states, but all we need
		    //  to know is we can neither read nor write
		    externalStorageAvailable = externalStorageWriteable = false;				    
			Log.d(LOG_TAG, "External Storage Not Available");
		}
						
		// if we can write to the SDCARD
		if (externalStorageAvailable && externalStorageWriteable) { 
			return context.getExternalFilesDir(Environment.DIRECTORY_MUSIC).getAbsolutePath() + "/";
		}else{
			return null;
		}
	}

	protected boolean minimumSpaceIsAvailable(String directory, int neededSize){
		StatFs stat = new StatFs(directory);		
		int availableBlocks=stat.getAvailableBlocks();
		int blockSize=stat.getBlockSize();
		long availableSize = (long)availableBlocks * (long)blockSize;
		return (availableSize > neededSize);
	}
	
}

