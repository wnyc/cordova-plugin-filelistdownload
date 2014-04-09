package org.nypr.cordova.filelistdownloadplugin;

public class Utilities {
	public static String stripArgumentsFromFilename(String filename) {
		int q = filename.lastIndexOf("?");
		if (q>=0){
			filename=filename.substring(0,q);
		}
		return filename;
	}
}
