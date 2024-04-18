// Configuration from JSON file
// Looks for file my.config.json
// If not found uses config.json the developer default file - do not change config.json

private final static int JAVA_MODE = 0;
private final static int ANDROID_MODE = 1;
int buildMode = JAVA_MODE;

int screenWidth = 1920; // default
int screenHeight = 1080;  // default
float screenAspectRatio;
int dividerSize = 10; // 2x2 photo collage layout divider line width

int cameraWidth = 1920; // default
int cameraHeight = 1080; // default
float cameraAspectRatio;
float cameraFrameRate = 30;

boolean doubleTrigger = false;
int doubleTriggerDelayMax = 1000;
int doubleTriggerDelayMin = 200;
int doubleTriggerDelay = doubleTriggerDelayMin;

int horizontalOffset = 0;
int verticalOffset = 0;

String eventText;
String instructionLineText;
String finalCountdownText = "Freeze!";

String titleText="3D Photo Booth";
String OUTPUT_FILENAME = "IMG_";
String OUTPUT_COMPOSITE_FILENAME = "IMG_";
String OUTPUT_FOLDER_PATH="output";  // where to store photos
String fileType = "jpg"; //  other posible file types are "png" "bmp"
String rawFileType = "png"; //  other possible file types "bmp"

String CAMERA_NAME_C920 = "HD Pro Webcam C920";
String CAMERA_NAME_USB = "USB Camera";
String CAMERA_NAME_UVC = "UVC Camera";
String CAMERA_NAME_BRIO = "Logitech BRIO";
String cameraName = CAMERA_NAME_C920;

// Camera Pipeline Examples for G-Streamer with Windows 10/11 and video processing library
String PIPELINE_C920 = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_USB = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=1920, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=1080, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_3D_USB_Camera = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=2560, height=960, framerate=30/1 ! jpegdec ! videoconvert";
String PIPELINE_UVC = "pipeline: ksvideosrc device-index=0 ! image/jpeg ! jpegdec ! videoconvert";  // works for UVC Camera AntVR CAP 2
String PIPELINE_BRIO = "pipeline: ksvideosrc device-index=0 ! image/jpeg, width=3840, height=2160, framerate=30/1 ! jpegdec ! videoconvert";
String pipeline = PIPELINE_BRIO; // default

String cameraOrientation;
int orientation = LANDSCAPE;  // Always using landscape presentation for 3D photography although twin cameras may be in portrait orientation
//int orientation = PORTRAIT;
boolean camera3D = false; 
boolean stereoWindow = false; // show stereo window pane work in progress!
float printWidth;
float printHeight;
float printAspectRatio = 4.0/6.0;  // default aspect ratio 4x6 inch print portrait orientation

int numberOfPanels = 1;
boolean mirrorPrint = false;  // mirror photos saved for print by horizontal flip
boolean mirror = true; // convert image to mirror image
boolean saveRaw = false; // save original camera image capture without filter
boolean anaglyph = false; // show 3D image as anaglyph
boolean crosseye = false; // left and right eye views interchanged

int countdownStart = 3;  // seconds
String ipAddress;  // photo booth computer IP Address
JSONObject configFile;
JSONObject configuration;
JSONObject display;
JSONObject camera;
JSONObject printer;

void initConfig() {
  if (buildMode == JAVA_MODE) {
    readConfig();
  } else if (buildMode == ANDROID_MODE) {
    //readAConfig();  // TODO call different configuration function for Android
  }
}

void readConfig() {
  String filenamePath = sketchPath()+File.separator+"config"+File.separator+"my_config.json";
  if (!fileExists(filenamePath)) {
    filenamePath = sketchPath()+File.separator+"config"+File.separator+"config.json"; // default for development code test
  }
  configFile = loadJSONObject(filenamePath);
  //configFile = loadJSONObject("config.json");
  //configFile = loadJSONObject(sketchPath("config")+File.separator+"config.json");
  configuration = configFile.getJSONObject("configuration");
  //DEBUG = configFile.getBoolean("debug");
  // for MultiCam.pde 
  try {
    multiCamEnabled = configFile.getBoolean("multiCamEnabled");
  }
  catch (Exception e) {
    multiCamEnabled = false;
  }
  mirror = configuration.getBoolean("mirrorScreen");
  try {
  saveRaw = configuration.getBoolean("saveRaw");
  } catch (Exception esr) {
    saveRaw = false;
  }
  countdownStart = configuration.getInt("countDownStart");
  fileType = configuration.getString("fileType");
  OUTPUT_FOLDER_PATH = configuration.getString("outputFolderPath");
  ipAddress = configuration.getString("IPaddress");
  if (DEBUG) println("ipAddress="+ipAddress);
  instructionLineText = configuration.getString("instructionLineText");
  eventText = configuration.getString("eventText");
  String countdownText = configuration.getString("finalCountdownText");
  if (countdownText != null) {
    finalCountdownText = countdownText;
  }
  display = configFile.getJSONObject("display");
  if (display != null) {
    screenWidth = display.getInt("width");
    screenHeight = display.getInt("height");
  }
  screenAspectRatio = (float)screenWidth/(float)screenHeight;
  camera = configFile.getJSONObject("camera");
  cameraName = camera.getString("name");
  cameraWidth = camera.getInt("width");
  cameraHeight = camera.getInt("height");
  cameraAspectRatio = (float) cameraWidth / (float) cameraHeight;
  if (DEBUG) println("cameraWidth="+cameraWidth + " cameraHeight="+cameraHeight+ " cameraAspectRatio="+cameraAspectRatio);
  cameraOrientation = camera.getString("orientation");
  cameraFrameRate = camera.getFloat("fps");
  if (cameraOrientation != null && cameraOrientation.equals("landscape")) {
    orientation = LANDSCAPE;
  } else {
    orientation = PORTRAIT;
  }
  pipeline = camera.getString("pipeline");
  if (DEBUG) println("pipeline="+pipeline);
  // 3D camera configuration
  try {
    camera3D = camera.getBoolean("3D");
  }
  catch (Exception en) {
    camera3D = false;
  }
  
  try {
    horizontalOffset = camera.getInt("horizontalOffset");
  }
  catch (Exception en) {
    horizontalOffset = 0;
  }
  
  try {
    verticalOffset = camera.getInt("verticalOffset");
  }
  catch (Exception en) {
    verticalOffset = 0;
  }
  
  if (DEBUG) println("3D camera="+camera3D+ " horizontalOffset="+horizontalOffset+" verticalOffset="+verticalOffset);
  if (DEBUG) println("configuration camera name="+cameraName+ " cameraWidth="+cameraWidth + " cameraHeight="+ cameraHeight);
  if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
  if (DEBUG) println("mirror="+mirror);
  if (DEBUG) println("horizontalOffset="+horizontalOffset);
  if (DEBUG) println("verticalOffset="+verticalOffset);
  printer = configFile.getJSONObject("printer");
  if (printer != null) {
    printWidth = printer.getFloat("printWidth");
    printHeight = printer.getFloat("printHeight");
    printAspectRatio = printWidth/printHeight;
    if (DEBUG) println("printAspectRatio="+printAspectRatio);
  }
}

// Check if file exists
boolean fileExists(String filenamePath) {
  File newFile = new File (filenamePath);
  if (newFile.exists()) {
    if (DEBUG) println("File "+ filenamePath+ " exists");
    return true;
  }
  return false;
}
