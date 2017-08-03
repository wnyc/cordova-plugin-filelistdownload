package org.nypr.cordova.filelistdownloadplugin;

import org.apache.cordova.CordovaWebView;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

public class FileListDownloadPlugin extends CordovaPlugin implements OnDownloadUpdateListener {

	protected static final String LOG_TAG = "FileListDownloadPlugin";

	protected DownloadHandler mDownloadHandler=null;
    protected CallbackContext connectionCallbackContext;
    protected String mUserAgent = null;
	
	public FileListDownloadPlugin() {
		Log.d(LOG_TAG, "FileListDownload Plugin constructed");
	}
	
	@Override
	public void initialize(CordovaInterface cordova, CordovaWebView webView) {
		if(mDownloadHandler==null){
			Log.d(LOG_TAG, "FileListDownload Plugin creating DownloadHandler");
			mDownloadHandler=new DownloadHandler();
		}
    this.connectionCallbackContext = null;
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
                this.connectionCallbackContext = callbackContext;
                mDownloadHandler.downloadPlaylist(cordova.getActivity().getApplicationContext(),this,args, mUserAgent);
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            }else if (action.equals("scanfilelist")) {
                Log.d(LOG_TAG, "Scan List of Files");
                this.connectionCallbackContext = callbackContext;
                mDownloadHandler.scanPlaylist(cordova.getActivity().getApplicationContext(),this,args, mUserAgent);
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
            }else if (action.equals("setuseragent")) {
                Log.d(LOG_TAG, "Set User Agent");
                this.connectionCallbackContext = callbackContext;
                mUserAgent = args.getString(0);
                PluginResult pluginResult = new PluginResult(PluginResult.Status.OK);
                pluginResult.setKeepCallback(true);
                callbackContext.sendPluginResult(pluginResult);
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
    if (this.connectionCallbackContext != null) {
      JSONObject o=new JSONObject();
      PluginResult result=null;
      try {
        o.put("type", "complete");
        result = new PluginResult(PluginResult.Status.OK, o);
      } catch (JSONException e){
        result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
      } finally {
        result.setKeepCallback(true);
        this.connectionCallbackContext.sendPluginResult(result);              
      }
    }
	}

	@Override
	public void onDownloadError(String filename, int code, String message) {
		Log.d(LOG_TAG,"onDownloadError " + code + "; " + message + "; " + filename );
    if (this.connectionCallbackContext != null) {
      JSONObject o=new JSONObject();
      PluginResult result=null;
      try {
        o.put("type", "error");
        o.put("filename", filename);
        o.put("code", code);
        o.put("message", message);
        result = new PluginResult(PluginResult.Status.OK, o);
      } catch (JSONException e){
        result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
      } finally {
        result.setKeepCallback(true);
        this.connectionCallbackContext.sendPluginResult(result);              
      }
    }
	}

  @Override
  public void onDownloadListProgressUpdate(String filename, int percent) {  
    if (this.connectionCallbackContext != null) {
      JSONObject o=new JSONObject();
      PluginResult result=null;
      try {
        o.put("type", "progress");
        o.put("filename", filename);
        o.put("percent", percent);
        result = new PluginResult(PluginResult.Status.OK, o);
      } catch (JSONException e){
        result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
      } finally {
        result.setKeepCallback(true);
        this.connectionCallbackContext.sendPluginResult(result);              
      }
    }
  }

	@Override
	public void onDownloadCanceled() {
		Log.d(LOG_TAG, "onDownloadCanceled");
    if (this.connectionCallbackContext != null) {
      JSONObject o=new JSONObject();
      PluginResult result=null;
      try {
        o.put("type", "cancel");
        result = new PluginResult(PluginResult.Status.OK, o);
      } catch (JSONException e){
        result = new PluginResult(PluginResult.Status.ERROR, e.getMessage());
      } finally {
        result.setKeepCallback(true);
        this.connectionCallbackContext.sendPluginResult(result);              
      }
    }
	}
}
