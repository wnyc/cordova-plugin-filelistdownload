var exec = require("cordova/exec");

/**
 * This is a global variable called exposed by cordova
 */    
var FileListDownload = function(){};

FileListDownload.prototype.downloadfilelist = function(success, error, json) {
  exec(success, error, "FileListDownloadPlugin", "downloadfilelist", json);
};

FileListDownload.prototype.scanfilelist = function(success, error, json) {
  exec(success, error, "FileListDownloadPlugin", "scanfilelist", json);
};

FileListDownload.prototype.setuseragent = function(success, error, userAgent) {
  exec(success, error, "FileListDownloadPlugin", "setuseragent", [userAgent]);
};

module.exports = new FileListDownload();
