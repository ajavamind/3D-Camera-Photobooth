// Multi Remote Camera Control
// Broadcasts focus and shutter trigger UDP commands on a local network to
// Android devices running Multi Remote Camera application or Arduino controllers with WiFi
// Open source Multi Remote Camera app is available here:
// https://sourceforge.net/projects/multi-remote-camera/
// https://sourceforge.net/p/multi-remote-camera/wiki/Home/
// App for download here:
// https://sourceforge.net/p/multi-remote-camera/code/ci/master/tree/remote/release/
// and Arduino devices waiting for UDP messages on the network

import netP5.*;
//import oscP5.*; // does not use this part of oscP5 library
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;
import java.net.DatagramSocket;

UdpClient udpClient;

int photoIndex = 0;  // next photo index for filename
int videoIndex = 0;  // next video index for filename
boolean useTimeStamp = true;
String numberFilename = ""; // last used number filename
String datetimeFilename = ""; // last used date_time filename
String lastFilename = ""; // last used filename

static final int SAME = 0;
static final int UPDATE = 1;
static final int NEXT = 2;
static final int PHOTO_MODE = 0;
static final int VIDEO_MODE = 1;
int mode = PHOTO_MODE;
int port;
boolean connected;
String broadcastIpAddress;
boolean multiCamEnabled = false;
boolean focus = false;
static final int UDPport = 8000;  // UDP port for Multi Remote Camera app
static final String HTTPport = "8080";

// Initialize Multi Camera trigger using Broadcast IP address for local network
void intializeMulti(String ipAddress) {
  broadcastIpAddress = ipAddress.substring(0, ipAddress.lastIndexOf("."))+".255";
  udpClient = null;
  if (!multiCamEnabled) {
    if (DEBUG) println("multiCamEnabled=false");
    return;
  }
  port = UDPport;
  try {
    udpClient = new UdpClient(broadcastIpAddress, port);  // from netP5.* library
    if (DEBUG) println("UdpClient "+ broadcastIpAddress);
  }
  catch (Exception e) {
    if (DEBUG) println("Wifi problem");
    udpClient = null;
  }
  connected = false;
  if (udpClient != null) {
    connected = true;
    if (DEBUG) println("Wifi connected "+broadcastIpAddress);
  } else {
    if (DEBUG) println("Wifi not connected "+broadcastIpAddress);
  }
}

void updatePhotoIndex() {
  photoIndex++;
  if (photoIndex > 9999) {
    photoIndex = 1;
  }
}

void updateVideoIndex() {
  videoIndex++;
  if (videoIndex > 9999) {
    videoIndex = 1;
  }
}

/**
 * get filename for Open Camera Remote
 *  param 0 update: SAME, UPDATE, NEXT
 *  param 1 mode
 */
String getFilename(int update, int mode) {
  String fn = "";
  if (useTimeStamp) {
    if (update == UPDATE || update == NEXT) {
      fn = getDateTime();
      datetimeFilename = fn;
    } else {  // SAME
      fn = datetimeFilename;
    }
  } else {
    if (mode == PHOTO_MODE) {
      if (update == SAME) {
        fn = number(photoIndex);
        numberFilename = fn;
      } else if (update == UPDATE) {
        updatePhotoIndex();
        fn = number(photoIndex);
        numberFilename = fn;
      } else { // NEXT
        fn = number(photoIndex+1);
      }
    } else {
      if (update == SAME) {
        fn = number(videoIndex);
        numberFilename = fn;
      } else if (update == UPDATE) {
        updateVideoIndex();
        fn = number(videoIndex);
        numberFilename = fn;
      } else {  // NEXT
        fn = number(videoIndex+1);
      }
    }
  }
  lastFilename = fn;
  return fn;
}

boolean isActive() {
  if (udpClient != null) {
    return true;
  }
  return false;
}

void stopUDP() {
  if (udpClient != null) {
    DatagramSocket ds = udpClient.socket();
    if (ds != null) {
      ds.close();
      ds.disconnect();
    }
    udpClient = null;
  }
}

void focusPush() {
  if (udpClient != null) {
    udpClient.send("F");
  }
}

void focusRelease() {
  focus = false;
  if (udpClient != null) {
    udpClient.send("R");
  }
}

void shutterPush() {
  if (udpClient != null) {
    udpClient.send("S"+getFilename(UPDATE, PHOTO_MODE));
  }
}

void shutterRelease() {
  if (udpClient != null) {
    udpClient.send("R");
  }
}

void record() {
  if (udpClient != null) {
    udpClient.send("V"+getFilename(UPDATE, VIDEO_MODE));
  }
}

void cameraOk() {
  if (udpClient != null) {
    udpClient.send("P"); // pause in video mode
  }
}

void shutterPushRelease() {
  if (udpClient != null) {
    udpClient.send("S"+getFilename(UPDATE, PHOTO_MODE));
    udpClient.send("R");
  }
}

void takePhoto(boolean doubleTrigger, boolean shutter) {
  if (doubleTrigger) {
    focusPush();
    shutterPush();
    delay(doubleTriggerDelay);
    if (shutter) {
      shutterPush();
    } else {
      shutterPushRelease();
    }
  } else {
    if (udpClient != null) {
      if (shutter) {
        udpClient.send("S"+getFilename(UPDATE, PHOTO_MODE));
      } else {
        udpClient.send("C"+getFilename(UPDATE, PHOTO_MODE));
      }
    }
  }
}

// Not used - for reference
PImage getPhoto(String name) {
  //String name;
  String filename = "";
  String filenameUrl = "";
  PImage lastPhoto = null;
  boolean showPhoto = false;
  String aFilename = "IMG_"+ getFilename(SAME, PHOTO_MODE)+ "_"+name+".jpg";
  filename = aFilename;
  String afilenameUrl = "http://"+ipAddress + ":" + HTTPport + "/" + aFilename;
  afilenameUrl.trim();
  afilenameUrl = afilenameUrl.replaceAll("(\\r|\\n)", "");
  String afilename = filename.replaceAll("(\\r|\\n)", "");
  if (DEBUG) println("result filename = " + afilename + " filenameURL= "+afilenameUrl);
  //if (!afilenameUrl.equals(filenameUrl)) {
  if (!afilenameUrl.equals(filenameUrl) || lastPhoto == null || lastPhoto.width <= 0 || lastPhoto.height <=0) {
    filename = afilename.substring(afilename.lastIndexOf('/')+1);
    filenameUrl = afilenameUrl;
    lastPhoto = loadImage(filenameUrl, "jpg");
    if (DEBUG) println("OCR getFilename loadImage "+filenameUrl);
    if (lastPhoto == null || lastPhoto.width == -1 || lastPhoto.height == -1) {
      showPhoto = false;
    } else {
      showPhoto = true;
    }
  }
  return lastPhoto;
}
