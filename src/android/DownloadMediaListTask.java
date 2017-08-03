package org.nypr.cordova.filelistdownloadplugin;

import java.io.File;
import java.util.HashSet;

import org.json.JSONArray;
import org.json.JSONException;

import android.content.Context;
import android.util.Log;

public class DownloadMediaListTask implements Runnable {
	
	protected static final String LOG_TAG = "DownloadMediaListTask";
	
	protected OnDownloadUpdateListener mDownloadListener;
	protected JSONArray mDownloadArray;
	protected Context mContext;
	protected DownloadMediaFileTask mCurrentDownloadMediaFileTask;
    protected String mUserAgent;
	
	private volatile boolean mCancel = false;
	
	public DownloadMediaListTask(Context c, OnDownloadUpdateListener listener, JSONArray downloadArray, String userAgent) {
		try {
			mContext=c;
			mDownloadListener=listener;
			mDownloadArray=downloadArray;
			mCancel=false;
                        mUserAgent = userAgent;
			// at some point this could become multiple download tasks...
			mCurrentDownloadMediaFileTask=new DownloadMediaFileTask();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	@Override
	public void run() {
		startDownload(mContext, mDownloadListener, mDownloadArray, mUserAgent);
	}
		
	public void cancelDownload(){
		mCancel=true;
		
		// cancel currently downloading file...
		mCurrentDownloadMediaFileTask.cancelFileDownload();
	}
	
	public void startDownload(Context context, OnDownloadUpdateListener listener, JSONArray downloadArray, String userAgent){
		Log.d(LOG_TAG, "Performing File Download. Count=" + downloadArray.length() );
				
		try { 
			String directory=DownloadMediaFileTask.getDirectory(context);
			String url;
			String filename;
			HashSet <String> doNotDownloadTheseFiles;
			
			// create the directory if it isn't there.
			createDirectory(directory);
			
			// purge files not in playlist(s). do this prior to download to ensure maximum capacity.
			doNotDownloadTheseFiles=purgeOrphanFiles(directory, listener, downloadArray);
				
			for(int i=0;i<downloadArray.length() &&!mCancel;i++){
				url=downloadArray.getJSONObject(i).getString("audio");
				filename=new File(url).getName().toLowerCase();
				filename=Utilities.stripArgumentsFromFilename(filename);
				// check if file already here
				if(!doNotDownloadTheseFiles.contains(filename)){
					// download the audio 
					//Log.d(LOG_TAG, "Downloading Audio File #" + (i+1) + ". Url=" + url);
					mCurrentDownloadMediaFileTask.startDownload(context, listener, url,filename,userAgent);
					/*
					// download the image. not sure if this is necessary
					url=downloadArray.getJSONObject(i).getString("image");
					destinationFile = directory + "/" + new File(url).getName();
					if(url!=null && url.compareTo("")!=0 ){
						Log.d(LOG_TAG, "Downloading Image File #" + (i+1) + ". Url=" + url);
						dl.startDownload(context, listener, url,destinationFile);
					}
					*/
				}else{
					Log.d(LOG_TAG, "Skipping download, file already on device. File #" + (i+1) + ". Url=" + url);
					// fire event notifying of 'completed' download
					listener.onDownloadListProgressUpdate(filename, 100);
				}
			}
			
			// send a different event if canceled?
			if(!mCancel){
				listener.onDownloadComplete();
			}else{
				listener.onDownloadCanceled();
			}
		} catch (JSONException e){
			// TODO throw error...
			e.printStackTrace();
		} catch (Exception e){
			e.printStackTrace();
		} finally {	
		}
	}
	
	public void scanForDownloadedFiles(Context context, JSONArray downloadArray) throws JSONException {
		String directory=DownloadMediaFileTask.getDirectory(context);
		String url;
		String filename;
		File file;
		
		for(int i=0;i<downloadArray.length();i++){
			url=downloadArray.getJSONObject(i).getString("audio");
			filename=new File(url).getName();
			filename=Utilities.stripArgumentsFromFilename(filename);
			file = new File(directory + (filename));
			if(file.exists()){
				mDownloadListener.onDownloadListProgressUpdate(filename, 100);
			} else {
				mDownloadListener.onDownloadListProgressUpdate(filename, 0);
			}
		}
	}
		
	protected HashSet<String> purgeOrphanFiles(String directory, OnDownloadUpdateListener listener, JSONArray downloadArray) throws JSONException {
		String url;
		String fileToKeep;
		HashSet <String>filesToKeep=new HashSet <String>();
		HashSet <String>filesAlreadyHere=new HashSet <String>();
		
		// build a hash of files for quick lookup
		for(int i=0;i<downloadArray.length();i++){
			url=downloadArray.getJSONObject(i).getString("audio");
			boolean force=false;
			if (downloadArray.getJSONObject(i).has("force")){
				try{
					force=downloadArray.getJSONObject(i).getBoolean("force");
				}catch(JSONException e){
					force=false;
				}
			}
			fileToKeep = new File(url).getName().toLowerCase();
			fileToKeep = Utilities.stripArgumentsFromFilename(fileToKeep);
			if(!force){
				filesToKeep.add(fileToKeep);
			}else{
				Log.d(LOG_TAG, "Forcing download of " + fileToKeep);
			}
			
			File f = new File(directory + "/" + fileToKeep);
			if(f.exists() && !force){
				listener.onDownloadListProgressUpdate(fileToKeep, 100);
			}else{
				listener.onDownloadListProgressUpdate(fileToKeep, 0);
			}
		}
		
		// check each existing file. if not in current download list, then purge
		File file = new File(directory, "");
	    if (file != null && file.isDirectory()) {
	        File[] files = file.listFiles();
	        if(files != null) {
	            for(File f : files) {
	            	// check against files to keep
	            	if(!filesToKeep.contains(f.getName().toLowerCase())){
	            		f.delete();
	            	}else{
	            		filesAlreadyHere.add(f.getName().toLowerCase());
	            	}
	            }
	        }
	    }
	    
	    // return a hash of files that are in the current list and already downloaded
	    return filesAlreadyHere;
	}

	protected void createDirectory(String directory){
		File f=new File(directory);
		if(f!=null){
			f.mkdir();
		}
	}
	
}

