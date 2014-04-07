package org.nypr.cordova.filelistdownloadplugin;

public interface OnDownloadUpdateListener {
	//public abstract void onDownloadProgressUpdate(int percent);
	public abstract void onDownloadComplete();
	public abstract void onDownloadError(String filename, int code, String message);
	public abstract void onDownloadListProgressUpdate(String fileName, int percent);
	//public abstract void onDownloadListComplete();
	public abstract void onDownloadCanceled();
}
