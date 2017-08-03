package org.nypr.cordova.filelistdownloadplugin;

import org.json.JSONArray;
import org.json.JSONException;

import android.content.Context;

public class DownloadHandler {
	protected static final String LOG_TAG = "DownloadHandler";
	
	protected JSONArray mCurrentJSON;
	protected Thread mCurrentThread;
	protected DownloadMediaListTask mCurrentDownloadTask;
	
	public DownloadHandler(){
		mCurrentJSON=null;
		mCurrentThread=null;
		mCurrentDownloadTask=null;
	}
	
	public void scanPlaylist(Context context, OnDownloadUpdateListener listener, JSONArray json, String userAgent) throws JSONException{
		if(mCurrentDownloadTask==null){
			mCurrentDownloadTask = new DownloadMediaListTask(context,listener, json, userAgent);
		}
		mCurrentDownloadTask.scanForDownloadedFiles(context, json);
	}
	
	public void downloadPlaylist(Context context, OnDownloadUpdateListener listener, JSONArray json, String userAgent) throws JSONException{
		
		Boolean restart=true;
		
		// check if download in progress
		if( mCurrentJSON!=null && mCurrentThread!=null && mCurrentDownloadTask!=null && mCurrentThread.isAlive()  ){
			if(mCurrentJSON.toString().equals(json.toString())){ // string compare may not be the best way
				// same JSON - continue download
				mCurrentDownloadTask.scanForDownloadedFiles(context, json);
				// cancel restart
				restart=false;
			}else{
				// stop the current thread
				mCurrentDownloadTask.cancelDownload();
			}
		}
		
		if(restart){		
			mCurrentJSON = json;
			mCurrentDownloadTask = new DownloadMediaListTask(context,listener, json, userAgent);
			mCurrentThread = new Thread(mCurrentDownloadTask);
			mCurrentThread.start();
		}
	}
}
