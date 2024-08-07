// 3D Webcam Photobooth Windows Application //<>//
// Copyright 2022-2024 Andy Modla
// This project is a work in progress.
// Build with Processing 4.3 IDE
// Changed OpenJDK version for Windows in Processing JRE java folder to
// JRE version: OpenJDK Runtime Environment Microsoft-8902769 (17.0.10+7) (build 17.0.10+7-LTS)
// Using Processing video library version 2.2.2 with GStreamer version 1.20.3

import processing.video.*;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Enumeration;
import java.util.Locale;

private static final boolean DEBUG = true;
private static final boolean DEBUGKEY = false;
private static final boolean DEBUG_ONSCREEN = false;
String VERSION = "2D/3D 2.4";

Capture video;
private final static int NUM_BUFFERS = 2;
volatile PImage[] camImage = new PImage[NUM_BUFFERS];
volatile int camIndex = 0;  // current buffer index
volatile int nextIndex = 1; // next buffer index

PFont font;
int fontSize;
int largeFontSize;
PhotoBoothController photoBoothController;
ImageProcessor imageProcessor;

PImage hwsbs;

String RENDERER = JAVA2D; // default recommended RENDERER to avoid unresolved OpenGL GPU problems, but slow video
// P2D and P3D use OPENGL and graphics processor
// OPENGL is not used here because of crashes that originate in GStreamer Video library
//String RENDERER = P2D; // a OpenJDK Java memory exception bug in OpenGL video library prevents this render mode from working with filters
//String RENDERER = P3D; // a OpenJDK Java memory exception bug in OpenGL video library prevents this render mode from working with filters

float FRAME_RATE = 30;

// Index values used for review variable
private static final int LIVEVIEW_ANAGLYPH = -2;  // live view Anaglyph index
private static final int LIVEVIEW = -1;  // live view SBS parallel index
private static final int REVIEW = 0; // saved SBS image index or 2D photo
private static final int REVIEW_ANAGLYPH = 1;  // saved Anaglyph image index
private static final int REVIEW_LEFT = 2; // saved left image index
private static final int REVIEW_RIGHT = 3; // saved right image index
private static final int REVIEW_END = 4; // outside saved image index
private static final int REVIEW_COLLAGE_END = 5;  // saved Collage 2D panel image index
int review = LIVEVIEW; // default no review available yet, live view SBS

// 3D output for stereo card format 6x4 print
private static final int MONO = 0;  // 2D Card
private static final int PARALLEL = 1;  // SBS 3D
private static final int STEREO_CARD = 2; // Stereo card for viewing with a stereoscope
int format = PARALLEL;  // default - feature used for cropping SBS for printing stereo card

// Legends are description pages of key code commands available for the booth operator
// These are read from text files in the data folder
int legendPage = -1;
int LEGENDS = 3;
String[] legend1;
String[] legend2;
String[] legend3;
String[][] legend;

String[] cameras = null;
int cameraIndex = 0;
boolean showCameras = false;
boolean clearBackground = false;
boolean screenshot = false;
int screenshotCounter = 1;
boolean printing = false;
PImage windowPane;
String printFilePath;  // Photo to print file path
String message; // global text message for status information
int messageTimeout;  // number of frames

// NOTE !!!!!!
/** The Processing IDE only allows one settings() function and
 * is automtically generated or copied by the Processing source pre-processor.
 * It will pick the first fullScreen or size() and move to settings() commenting out the original in setup()
 * Auxilary display could be dynamically created without defining in a json config file.
 * Currently auxilary displays are built from json config file
 * The main display assumes monitor 1 in Windows.
 */

/**
 * setup reads the configuration file but fullScreen() is actually called before in settings()
 */
public void setup() {
  initConfig();  // read JSON configuration file my_config.json
  fullScreen(RENDERER, mainDisplay.id);  // photo booth main display on monitor 1
  // debug renderer options only applies to main display 1
  //size(1080, 1920, RENDERER);  // for debug vertical monitor for portrait display, used with 2D camera
  //size(1920, 1080, RENDERER);  // matches monitor for landscape 3D
  //size(3840, 2160, RENDERER);  // for debug with 4K monitor
  if (camera3D) {
    format = PARALLEL;
  } else {
    format = MONO;
  }
  FRAME_RATE = cameraFrameRate;  // Processing loop frame rate

  screenWidth = width;
  screenHeight = height;
  if (DEBUG) println("screenWidth="+screenWidth + " screenHeight="+screenHeight);
  photoBoothController = new PhotoBoothController();
  intializeMulti(ipAddress);  // address of a device on this private network
  frameRate(FRAME_RATE); // set draw loop frame rate
  smooth();

  // font type and size setup
  font = loadFont("SansSerif-64.vlw"); // font file in data folder
  textFont(font);
  if (screenWidth >= 3840) {
    fontSize = 96;
  } else if (screenWidth >= 1920) {
    fontSize = 48;
  } else if (screenWidth >= 960) {
    fontSize = 24;
  } else {
    fontSize = 24;
  }
  textSize(fontSize);
  largeFontSize = 6*fontSize;

  // read legend files that describe key entry functions
  legend1 = loadStrings("keyLegend.txt");
  legend2 = loadStrings("keyLegend2.txt");
  legend3 = loadStrings("keyLegend3.txt");
  legend = new String[][] { legend1, legend2, legend3};

  // where output file go
  if (OUTPUT_FOLDER_PATH.equals("output")) {  // default folder name
    OUTPUT_FOLDER_PATH = sketchPath("output");
  }
  if (DEBUG) println("OUTPUT_FOLDER_PATH="+OUTPUT_FOLDER_PATH);

  // get list of cameras connected
  boolean camAvailable = false;
  cameraIndex = 0;  // default camera index
  int retrys = 10;
  while (!camAvailable && retrys > 0) {
    try {
      cameras = Capture.list();
      retrys--;
    }
    catch (Exception ex) {
      cameras = null;
    }
    if (cameras != null && cameras.length > 0) {
      break;
    }
    delay(200); // wait 200 Ms between retries to get the camera list
  }

  if (cameras == null || cameras.length == 0 && !cameraRtsp) {
    if (DEBUG) println("There are no cameras available for capture.");
    video = null;
  } else {
    if (DEBUG) println("Available cameras:");
    camAvailable = true;
    for (int i = 0; i < cameras.length; i++) {
      if (DEBUG) println(cameras[i]+" "+i);
      if (cameras[i].equals(cameraName)) {
        cameraIndex = i;
      }
    }
    if (cameras.length > 0) {
      if (DEBUG) println("Found Camera: "+cameras[cameraIndex]+".");
    }

    //String dev = cameras[cameraIndex].substring(0,cameras[cameraIndex].lastIndexOf(" #"));
    //println(dev+".");
    //String dev = cameras[cameraIndex];
    //String[] features = Capture.getCapabilities(dev);
    //if (DEBUG) printArray(features);

    // replace index number in PIPELINE
    //pipeline = pipeline.replaceFirst("device-index=0", "device-index="+str(cameraIndex));
    // The camera can be initialized directly using an
    // element from the array returned by list()
    // default first camera found at index 0
    if (camAvailable || (cameraRtsp && pipeline != null) ) {

      //video = new Capture(this, cameras[cameraIndex]);
      // using default pipeline only captured low resolution of camera example 640x480 for HD Pro Webcam C920
      // pipeline for windows 10 - captures full HD 1920x1080 for HD Pro Webcam C920

      if (pipeline != null) {
        video = new Capture(this, cameraWidth, cameraHeight, pipeline);
        if (DEBUG) println("Using PIPELINE=" + pipeline);
      } else {
        video= new Capture(this, cameraWidth, cameraHeight, cameras[cameraIndex]);
        if (DEBUG) println("Using camera: " + cameras[cameraIndex] );
      }
      video.start();
      if (DEBUG) println("Video start");
    }
  }

  noStroke();
  noCursor();
  background(0);

  // create half width monitor 2 when configured
  if (auxDisplay.status) {
    createAuxDisplay("Display2");
  }

  imageProcessor = new ImageProcessor();
  windowPane = imageProcessor.createWindowPane();
  // force focus on window so that key input always works without a mouse
  if (buildMode == JAVA_MODE) {
    try {
      if (RENDERER.equals(P2D) || RENDERER.equals(P3D)) {
        ((com.jogamp.newt.opengl.GLWindow) surface.getNative()).requestFocus();  // for P2D
      } else {
        ((java.awt.Canvas) surface.getNative()).requestFocus();  // for JAVA2D (default)
      }
    }
    catch (Exception ren) {
      println("Renderer: "+RENDERER+ " Window focus exception: " + ren.toString());
    }
  }
  // set count down Interval
  //photoBoothController.setCountInterval(countInterval, countdownStart);
  photoBoothController.setCountdownStart(countdownStart);
  surface.setTitle(titleText);
  if (DEBUG) println("Renderer: "+RENDERER);
  if (DEBUG) println("finished setup()");
}

public void draw() {
  //System.gc();
  // process any key or mouse inputs to steer screen drawing
  int command = keyUpdate(); // decode key inputs received on threads outside the draw thread loop

  if (legendPage >= 0) {
    background(0);
    drawLegend(legend[legendPage]);
    saveScreenshot();
    return;
  }

  if (showCameras && cameras != null) {
    background(0);
    showCamerasList();
    saveScreenshot();
    return;
  }
  if (clearBackground) {
    clearBackground = false;
    background(0);
  }

  if (video == null) {
    background(0);
    fill(255);
    text("No Cameras Available. ", 10, screenHeight/2);
    text("Check camera connection or other applications using the camera.", 10, screenHeight/2+screenHeight/16);
    text("Press Q Key to Exit.", 10, screenHeight/2+ screenHeight/8);
    if (command == ENTER) {
      exit();
    }
    saveScreenshot();
    return;
  }

  if (video.available()) {
    if (RENDERER.equals(P2D) || RENDERER.equals(P3D)) {
      // temporary until video library fixes bug
      image(video, 0, 0, 0, 0);  // needed as work around issue with Capture video library buffer
      video.loadPixels(); // work around issue with Capture video library buffer
      video.read();
      camImage[nextIndex] = video;  // double buffering
    } else {  // JAVA2D
      image(video, 0, 0, 0, 0);  // needed as work around issue with Capture video library buffer
      video.read();
      camImage[nextIndex] = video.copy();  // double buffering
    }
    // set next buffer location
    camIndex = nextIndex;
    nextIndex++;
    nextIndex = nextIndex & 1; // alternating 2 buffers
  }

  if (photoBoothController.endPhotoShoot) {
    photoBoothController.lastPhoto(); // keep drawing last photo taken for 2 seconds using oldShootCounter as a frame counter
  } else {
    if (review > LIVEVIEW) {
      photoBoothController.drawLast();
    } else {
      photoBoothController.processImage(camImage[camIndex]);
    }
    drawText();  //  TODO make PGraphic
    if (photoBoothController.isPhotoShoot) {
      try {
        photoBoothController.drawCountdownSequence();
      }
      catch (Exception exx) {
        println("drawPhotoShoot "+exx);
        exx.printStackTrace();
        exit();
      }
    }
  }

  // Display status message if present
  drawMessage();

  if (camera3D && stereoWindow) {
    // show stereo window pane
    //blend(0, 0, input.width, input.height, 0, 0, input.width, input.height, MULTIPLY);
    image(windowPane, 0, 0);
  }

  // Drawing finished, check for screenshot file capture
  saveScreenshot();

  // Drawing finished, convert for main monitor for 3d display when configured for it
  convertScreen();
}

void drawLegend(String[] legend) {
  fill(255);
  int vertAdj = fontSize;
  int horzAdj = 20;

  for (int i=0; i<legend.length; i++) {
    if (i==0) {
      text(legend[i] + " Version: "+ VERSION, horzAdj, vertAdj*(i+1));
    }
    text(legend[i], horzAdj, vertAdj*(i+1));
  }
}

void showCamerasList() {
  fill(255);
  int vertAdj = fontSize;
  int horzAdj = 20;
  int i = 0;
  String appd = "";
  if (cameras.length == 0) {
    if (cameraRtsp) {
      appd = "RTSP Camera";
    } else {
      appd = "No Cameras Available";
    }
    text(appd, horzAdj, vertAdj*(i+1));
    i++;
  } else {
    while ( i < cameras.length) {
      appd = "";
      if (cameraIndex == i) appd = " selected";
      text(cameras[i]+appd, horzAdj, vertAdj*(i+1));
      i++;
    }
  }
  // show configuration list
  i++;
  text("Camera Width="+cameraWidth + " Height="+ cameraHeight, horzAdj, vertAdj*(i++));
  text("FRAME_RATE="+FRAME_RATE, horzAdj, vertAdj*(i++));
  text("camera3D="+(camera3D==true ? "ON": "OFF"), horzAdj, vertAdj*(i++));
  text("saveRaw="+(saveRaw==true ? "ON": "OFF"), horzAdj, vertAdj*(i++));
  text("mirror="+(mirror==true ? "ON": "OFF"), horzAdj, vertAdj*(i++));
  text("mirrorPrint="+(mirrorPrint==true ? "ON": "OFF"), horzAdj, vertAdj*(i++));
  text("Anaglyph="+(anaglyph==true ? "ON": "OFF"), horzAdj, vertAdj*(i++));
  text("orientation="+(orientation==LANDSCAPE ? "LANDSCAPE":"PORTRAIT"), horzAdj, vertAdj*(i++));
  text("horizontalOffset="+horizontalOffset, horzAdj, vertAdj*(i++));
  text("verticalOffset="+verticalOffset, horzAdj, vertAdj*(i++));
  text("multiCamEnabled=" + multiCamEnabled, horzAdj, vertAdj*(i++));
  text("Broadcast IPAddress="+ broadcastIpAddress, horzAdj, vertAdj*(i++));
  text("doubleTrigger="+doubleTrigger, horzAdj, vertAdj*(i++));
  text("doubleTriggerDelay="+doubleTriggerDelay+" ms", horzAdj, vertAdj*(i++));
  text("numberOfPanels="+numberOfPanels, horzAdj, vertAdj*(i++));
  text("config filename="+configFilename, horzAdj, vertAdj*(i++));
}

// Draw instruction and event title text on screen
void drawText() {
  fill(192);  // light gray
  if (review <= LIVEVIEW) {
    float angleForText;
    float tw;
    if (orientation == LANDSCAPE) {
      drawScreenText(instructionLineText, 0, screenHeight/24);
      drawScreenText(eventText, 0, screenHeight-screenHeight/32);

      if (format == STEREO_CARD) {
        drawScreenText(featureText, 0, screenHeight-screenHeight/16-10);
      }
    } else {  // portrait mode not used yet with 3D and then only portrait orientation twin cameras
      //  TODO use drawScreenText()
      angleForText = radians(270);
      tw = textWidth(instructionLineText);
      pushMatrix();
      translate(screenWidth/32, screenHeight/2+tw/2);
      rotate(angleForText);
      text(instructionLineText, 0, 0);
      popMatrix();

      tw = textWidth(eventText);
      pushMatrix();
      translate(screenWidth-screenWidth/32, screenHeight/2+tw/2);
      rotate(angleForText);
      text(eventText, 0, 0);
      popMatrix();
    }
  }
}

void drawScreenText(String txt, int x, int y) {
  float angleForText;
  float tw;

  if (camera3D && !anaglyph) {
    // draw same text string to left and right eye views on screen
    pushMatrix();
    tw = textWidth(txt);
    translate(x+screenParallax+screenWidth/4- tw/2, y); // left
    text(txt, 0, 0);
    popMatrix();
    pushMatrix();
    translate(x+screenWidth/4+screenWidth/2- tw/2, y); // right
    text(txt, 0, 0);
    popMatrix();
  } else if (!camera3D || anaglyph) {
    // draw single text string on screen
    pushMatrix();
    tw = textWidth(txt);
    translate(screenWidth/2- tw/2, y);
    text(txt, 0, 0);
    popMatrix();
  }
}

void setMessage(String msg, int seconds) {
  message = msg;
  messageTimeout = seconds * (int) frameRate;
}

// draw Status or Error Message in center of screen
int drawMessage() {
  if (messageTimeout <= 0 ) {
    message = null;
    return messageTimeout;
  }
  //float angleText;
  float tw;
  fill(color(255, 255, 0)); // yellow
  drawScreenText(message, 0, screenHeight/12);
  messageTimeout--;
  return messageTimeout;
}

void saveScreenshot() {
  if (screenshot) {
    screenshot = false;
    saveScreen(OUTPUT_FOLDER_PATH, "screenshot_", number(screenshotCounter), "png");
    if (DEBUG) println("save "+ "screenshot_" + number(screenshotCounter));
    screenshotCounter++;
  }
}

// Save image of the composite screen
void saveScreen(String outputFolderPath, String outputFilename, String suffix, String filetype) {
  save(outputFolderPath + File.separator + outputFilename + suffix + "." + filetype);
}

String getDateTime() {
  Date current_date = new Date();
  String timeStamp = new SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(current_date);
  return timeStamp;
}

// calls exiftool exe in the path
// sets portrait orientation by rotate camera left
void setEXIF(String filename) {
  try {
    Process process = Runtime.getRuntime().exec("exiftool -n -orientation=6 "+filename);
    process.waitFor();
  }
  catch (Exception ex) {
  }
}

// calls printPhoto.bat in the sketch path
void printPhoto(String filenamePath) {
  if (DEBUG) println("printPhoto "+filenamePath);
  if (filenamePath == null) return;
  if (DEBUG) println("process "+sketchPath() + File.separator + "printPhoto.bat "+ filenamePath);
  printFilePath = filenamePath;
  thread("sendPhotoToPrinter");
}

// Processing thread call, no parameters, works during draw()
void sendPhotoToPrinter() {
  if (messageTimeout == 0) {
    printing = false;
  }
  if (printing) return;
  printing = true;
  if (DEBUG) println("sendPhotoToPrinter");
  try {
    Process process = Runtime.getRuntime().exec(sketchPath()+ File.separator + "printPhoto.bat "+printFilePath);
    setMessage("Sending Photo to Printer", 6);
    process.waitFor();
  }
  catch (Exception ex) {
    if (DEBUG) println("Print Error "+ printFilePath);
  }
  if (DEBUG) println("Print Complete");
  //message = null; // clear message
}


void stop() {
  if (DEBUG) println("stop");
  video.stop();
  super.stop();
}

// Add leading zeroes to number with a limit of 4 digits
String number(int index) {
  // fix size of index number at 4 characters long
  if (index == 0)
    return "";
  else if (index < 10)
    return ("000" + String.valueOf(index));
  else if (index < 100)
    return ("00" + String.valueOf(index));
  else if (index < 1000)
    return ("0" + String.valueOf(index));
  return String.valueOf(index);
}
