# File List Download PhoneGap/Cordova Plugin

### Platform Support

This plugin supports PhoneGap/Cordova apps running on both iOS and Android.  

The iOS portion currently utilizes an outdated verson of ASIHTTPRequest. Plans are in the works to switch to AFNetworking.  

### Version Requirements

This plugin is meant to work with Cordova 3.5.0+.

References:  
http://allseeing-i.com/ASIHTTPRequest/

## Installation

#### Automatic Installation using PhoneGap/Cordova CLI (iOS and Android)
1. Make sure you update your projects to Cordova iOS version 3.5.0+ before installing this plugin.

        cordova platform update ios
        cordova platform update android

2. Install this plugin using PhoneGap/Cordova cli:

        cordova local plugin add https://github.com/wnyc/cordova-plugin-filelistdownload.git

## Usage

    // all responses from the audio player are channeled through successCallback and errorCallback  

    // request a file list to be downloaded  
    // any files that are downloaded but not on the list will be deleted  
    window.filelistdownload.downloadfilelist( successCallback,  
                                              errorCallback,  
                                              // list of files to download  
                                              // force: true will cause the file to be downloaded even if it already exists on the device  
                                              [  
                                                {  
                                                  "audio": "http://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/news/news20141031_cms410295_pod.mp3",  
                                                  "force": false  
                                                },  
                                                {  
                                                  "audio": "http://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/moneytalking/moneytalking20141031pod.mp3",  
                                                  "force": false  
                                                },  
                                                {  
                                                  "audio": "http://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/news/news20141031_cms410807_pod.mp3",  
                                                  "force": false  
                                                }  
                                              ]  
                                            );  

    // scan the file directory to ascertain which files from the given list are currently downloaded  
    window.filelistdownload.scanfilelist( successCallback,  
                                          errorCallback,  
                                          [  
                                            {  
                                              "audio": "http://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/news/news20141031_cms410295_pod.mp3"  
                                            },  
                                            {  
                                              "audio": "http://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/moneytalking/moneytalking20141031pod.mp3"  
                                            },  
                                            {  
                                              "audio": "http://www.podtrac.com/pts/redirect.mp3/audio.wnyc.org/news/news20141031_cms410807_pod.mp3"  
                                            }  
                                          ]  
                                        );  

 
    // example of a callback function  
    var successCallback = function(result) {  
      console.log('download callback ' + JSON.stringify(result));  
      if (result.type==='progress') {  
        console.log('progress - ' + result.filename + ' is ' + result.percent + '% downloaded');  
      } else if (result.type==='error') {  
        console.log("error");  
        console.log("file: " + result.filename);  
        console.log("code: " + result.code);  
        console.log("message: " + result.message);  
      } else if (result.type==='complete') {  
        console.log('file list download complete');  
      } else {  
        console.log('unhandled type (' + result.type + ')');  
      }  
    };  
