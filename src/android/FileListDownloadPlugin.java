package org.nypr.cordova.filelistdownloadplugin;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.json.JSONArray;
import org.json.JSONException;

import android.util.Log;

public class FileListDownloadPlugin extends CordovaPlugin implements OnDownloadUpdateListener {

	protected static final String LOG_TAG = "FileListDownloadPlugin";

	protected DownloadHandler mDownloadHandler=null;
	
	public FileListDownloadPlugin() {
		Log.d(LOG_TAG, "FileListDownload Plugin constructed");
	}
	
	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		if(mDownloadHandler==null){
			Log.d(LOG_TAG, "FileListDownload Plugin creating DownloadHandler");
			mDownloadHandler=new DownloadHandler();
		}
		super.initialize(cordova, webView);
		Log.d(LOG_TAG, "FileListDownload Plugin initialized");
	}
	
	@Override
	public void onDestroy() {
		Log.d(LOG_TAG, "FileListDownload Plugin destroying");
		mDownloadHandler=null;
		super.onDestroy();
	}

	@Override
	public void onReset() {
		Log.d(LOG_TAG, "FileListDownload Plugin onReset--WebView has navigated to new page or refreshed.");
		super.onReset();
	}
	
	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
		boolean ret=true;
		try {
			
			if (action.equals("downloadfilelist")) {
				Log.d(LOG_TAG, "Download List of Files");					
				mDownloadHandler.downloadPlaylist(cordova.getActivity().getApplicationContext(),this,args);
				callbackContext.success();
			}else if (action.equals("scanfilelist")) {
				Log.d(LOG_TAG, "Scan List of Files");					
				mDownloadHandler.scanPlaylist(cordova.getActivity().getApplicationContext(),this,args);
				callbackContext.success();
			}else{
				callbackContext.error(LOG_TAG + " error: invalid action (" + action + ")");
				ret=false;
			}
		} catch (JSONException e) {
			callbackContext.error(LOG_TAG + " error: invalid json");
			ret = false;
		} catch (Exception e) {
			callbackContext.error(LOG_TAG + " error: " + e.getMessage());
			ret = false;
		}
		return ret;
	}
	
	@Override
	public void onDownloadComplete() {
		Log.d(LOG_TAG,"onDownloadComplete" );
		this.webView.sendJavascript("NYPRNativeFeatures.prototype.DownloadComplete();");
	}

	@Override
	public void onDownloadError(String filename, int code, String message) {
		Log.d(LOG_TAG,"onDownloadError " + code + "; " + message + "; " + filename );
		this.webView.sendJavascript("NYPRNativeFeatures.prototype.DownloadError('" + filename + "',"+ code + ",'" + message + "');");
	}

	@Override
	public void onDownloadListProgressUpdate(String fileName, int percent) {	
		this.webView.sendJavascript("NYPRNativeFeatures.prototype.DownloadProgress("+ percent + ",'" + fileName + "');");
	}

	@Override
	public void onDownloadCanceled() {
		Log.d(LOG_TAG, "Download Canceled. Add call to Javascript.");
	}
}
