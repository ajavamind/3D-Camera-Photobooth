// Configuration from JSON file
// Looks for file my.config.json
// If not found uses config.json the developer default file - do not change config.json

/** Display Monitor Description */
class Monitor {
  int id; // identifier
  String format;  // 2D, 3D (side by side left/right), 3DHW (half width side by side left/right)
  int screenWidth; // configured screen width in pixels (not maximum display width)
  int screenHeight;  // configured screen height pixels (not maximum display height)
  boolean status = false; // true: on, false: off or not present
  float AR; // screen aspect ratio

  // constructor with defaults
  Monitor(int id, boolean status) {
    this.id = id;
    this.status = status;
    screenWidth = 1920;  // default
    screenHeight = 1080; // default
    format = "2D";
  }
}

String osName;   // "Linux", "Windows", "Android", "iOS"
boolean isWindows;
boolean isLinux;
private final static int JAVA_MODE = 0;
private final static int ANDROID_MODE = 1;
int buildMode = JAVA_MODE;

String configFilename;

static final int MONO_SCREEN = 0;
static final int HWSBS_SCREEN = 1;
static final int COLUMN_SCREEN = 2;
static final int ROW_SCREEN = 3;
int screenMode = MONO_SCREEN;  // 2D screen monitor mode default

// Must be defined as global variable for use by Processing preprocessor
// monitor id fixed on next line, but does not have to be 1
// moniors must be connected to HDMI numbered port, no gaps in sequence of displays present
Monitor mainDisplay = new Monitor(1, true);  // monitor id cannot be overwritten by json config
Monitor auxDisplay = new Monitor(2, false); // defaults to not present (false)

// Main display parameters
int screenWidth = 1920; // default
int screenHeight = 1080;  // default
float screenAspectRatio;

int cameraWidth = 1920; // default
int cameraHeight = 1080; // default
float cameraAspectRatio;
float cameraFrameRate = 30;

boolean doubleTrigger = false;
int doubleTriggerDelayMax = 1000;
int doubleTriggerDelayMin = 200;
int doubleTriggerDelay = doubleTriggerDelayMin;

volatile int horizontalOffset = 0;
volatile int verticalOffset = 0;

// 3D mode parallax values used for showing text in 3D images at a fixed depth
int screenParallax = 5;  // for screen text like countdown, event, title text, etc.
int printParallax = 0;  // for printed stereo cards

String eventText = "3D Camera Photo Booth";
String eventInfoText = "3D Camera Photo Booth";
String instructionLineText = "";
String featureText = "Stereo Card Print Format";
String finalCountdownText = "Smile!";
String titleText="3D Camera Photo Booth";
int dividerSize = 10; // 2x2 photo collage layout divider line width

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
boolean cameraRtsp = false;
boolean stereoWindow = false; // show stereo window pane work in progress!
float printWidth= 6;  // inches
float printHeight = 4; // inches
float printAspectRatio = 6.0/4.0;  // default aspect ratio 6x4 inch print landscape orientation
int printPxWidth;
int printPxHeight;
float printPPI = 300.0;

volatile int numberOfPanels = 1;
int reviewNumberOfPanels = 1;
boolean mirrorPrint = false;  // mirror photos saved for print by horizontal flip
boolean mirror = true; // convert image to mirror image
boolean saveRaw = false; // save original camera image capture without filter
boolean anaglyph = false; // show 3D image as anaglyph
boolean crosseye = false; // left and right eye views interchanged
boolean zoomPhoto = false; // zoom image to verify dual camera focus for test or setup
int zoomPhotoIndex = 0; // zoom left (0) or right (1) to verify dual camera focus for test or setup

int countdownStart = 3;  // seconds
String ipAddress;  // photo booth computer IP Address
JSONObject configFile;
JSONObject configuration;
JSONObject display;
JSONObject camera;
JSONObject printer;

void initConfig() {
  String osName = System.getProperty("os.name");
  if (DEBUG) println("osName="+osName);
  isWindows = System.getProperty("os.name").startsWith("Windows");
  isLinux = System.getProperty("os.name").startsWith("Linux");   // sketch works with linux except printing TODO

  String name = sketchPath()+File.separator+"config"+File.separator+"lastUsedConfig.txt";
  if (DEBUG) println(name);
  String[] lines = loadStrings(name);
  configFilename = pickConfigFilename(lines);
  if (DEBUG) println("Last used config filename="+configFilename);

  if (buildMode == JAVA_MODE) {
    readConfig(configFilename);
  } else if (buildMode == ANDROID_MODE) {
    //readAndroidConfig();  // TODO call different configuration function for Android
  }
}

/**
 * Pick configuration filename starting with * character from array of Strings
 * Ignore all other lines
 *
 */
String pickConfigFilename(String[] lines) {
  String filename = "my_config.json";  // default configuration filename
  if (lines == null) {
  } else if (lines.length == 0) {
  } else {
    for (int i=0; i<lines.length; i++) {
      if (lines[i].startsWith("*")) {
        filename = lines[i].substring(1);
        break;
      }
    }
  }
  return filename;
}

void readConfig(String configFilename) {
  String temp;
  String filenamePath = sketchPath()+File.separator+"config"+File.separator+configFilename;
  if (!fileExists(filenamePath)) {
    filenamePath = sketchPath()+File.separator+"config"+File.separator+"config.json"; // default for development code test
  }

  // get the configuration file json file
  configFile = loadJSONObject(filenamePath);
  //configFile = loadJSONObject("config.json");
  //configFile = loadJSONObject(sketchPath("config")+File.separator+"config.json");

  /* Photo booth configuration section --------------------------------------*/
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
  mirrorPrint = configuration.getBoolean("mirrorPrint");
  try {
    saveRaw = configuration.getBoolean("saveRaw");
  }
  catch (Exception esr) {
    saveRaw = false;
  }
  countdownStart = configuration.getInt("countDownStart");
  temp = configuration.getString("fileType");
  if (temp != null) fileType = temp;
  temp = configuration.getString("outputFolderPath");
  if (temp != null) OUTPUT_FOLDER_PATH = temp;
  temp = configuration.getString("IPaddress");
  if (temp != null) ipAddress = temp;
  if (DEBUG) println("ipAddress="+ipAddress);
  temp = configuration.getString("instructionLineText");
  if (temp != null) instructionLineText = temp;
  if (DEBUG) println("instructionLineText=\""+instructionLineText+"\"");
  temp = configuration.getString("eventText");
  if (temp != null) eventText = temp;
  temp = configuration.getString("eventInfoText");
  if (temp != null) eventInfoText = temp;
  if (DEBUG) println("eventText=\""+eventText+"\"");
  if (DEBUG) println("eventInfoText=\""+eventInfoText+"\"");
  temp = configuration.getString("finalCountdownText");
  if (temp != null) finalCountdownText = temp;

  /* Display section ---------------------------------------------------------*/
  display = configFile.getJSONObject("display");
  if (display != null) {
    screenWidth = display.getInt("width");
    screenHeight = display.getInt("height");
    mainDisplay.screenWidth = display.getInt("width");
    mainDisplay.screenHeight = display.getInt("height");
    mainDisplay.AR = (float)mainDisplay.screenWidth/(float)mainDisplay.screenHeight;
    mainDisplay.status = true;
    mainDisplay.id = 1;
    String tempf = display.getString("format");
    if (tempf != null) {
      mainDisplay.format = tempf;
    } else {
      mainDisplay.format = "2D";
    }
  }
  screenAspectRatio = (float)screenWidth/(float)screenHeight;
  if (DEBUG) println("display id="+mainDisplay.id + " format="+mainDisplay.format);

  display = configFile.getJSONObject("display2");
  if (display != null) {
    auxDisplay.id = display.getInt("id");
    auxDisplay.screenWidth = display.getInt("width");
    auxDisplay.screenHeight = display.getInt("height");
    auxDisplay.AR = (float)auxDisplay.screenWidth/(float)auxDisplay.screenHeight;
    try {
      auxDisplay.status = display.getBoolean("status");
    }
    catch (Exception ne) {
      auxDisplay.status = false;
    }
    temp = display.getString("format");
    if (temp != null) {
      auxDisplay.format = temp;
    } else {
      auxDisplay.format = "2D";
    }
    if (DEBUG) println("display id="+auxDisplay.id + " format="+auxDisplay.format+
      " status="+auxDisplay.status);
  }

  /* Camera description section ----------------------------------------------*/
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
    cameraRtsp = camera.getBoolean("rtsp");
  }
  catch (Exception er) {
  }
  if (DEBUG) println("cameraRtsp="+cameraRtsp);
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

  /* Printer section -----------------------------------------------------*/
  printer = configFile.getJSONObject("printer");
  if (printer != null) {
    printWidth = printer.getFloat("printWidth");
    printHeight = printer.getFloat("printHeight");
    printAspectRatio = printWidth/printHeight;
  }
  printPxWidth = (int)(printWidth*printPPI);
  printPxHeight = (int)(printHeight*printPPI);
  if (DEBUG) println("printWidth="+printWidth+" printHeight="+printHeight+" printAspectRatio="+printAspectRatio);
  if (DEBUG) println("printPxWidth="+printPxWidth+" printPxHeight="+printPxHeight);
}

/**
 * Fill in Monitor object from configuration file
 * when there is no configuration defined in json file, set monitor.status to false
 * unless id == 1 main display
 */
Monitor getDisplayConfig(String name, Monitor monitor) {
  JSONObject display;
  try {
    display = configFile.getJSONObject(name);
    if (display != null) {
      monitor.id = display.getInt("id");
      monitor.screenWidth = display.getInt("width");
      monitor.screenHeight = display.getInt("height");
      monitor.AR = (float)auxDisplay.screenWidth/(float)auxDisplay.screenHeight;
      try {
        monitor.status = display.getBoolean("status");
      }
      catch (Exception ne) {
        monitor.status = false;
      }
      String temp = display.getString("format");
      if (temp != null) {
        monitor.format = temp;
      } else {
        monitor.format = "2D";
      }
      if (DEBUG) println("display id="+ monitor.id + " format="+ monitor.format+
        " status="+ monitor.status);
      return monitor;
    }
  }
  catch (Exception re) {
    if (monitor.id == 1) monitor.status = true; else monitor.status = false;
  }
  return monitor;
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
