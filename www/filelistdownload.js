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

module.exports = new FileListDownload();
