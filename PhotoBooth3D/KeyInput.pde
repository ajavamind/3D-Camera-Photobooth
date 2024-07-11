// Keyboard and Mouse input handling
// There is limited GUI used for the photo booth
// These key and mouse commands are for test and debug
// The mouse commands are used with a buzzer box containing a repurposed wireless mouse.
// These codes (ASCII) are for Java applications
// Android key codes (not implemented) differ with some keys

static final int KEYCODE_BACKSPACE = 8;
static final int KEYCODE_TAB = 9;
static final int KEYCODE_ENTER = 10;
static final int KEYCODE_ESC = 27;
static final int KEYCODE_SPACE = 32;
static final int KEYCODE_COMMA = 44;
static final int KEYCODE_MINUS = 45;
static final int KEYCODE_UNDERSCORE = 45;
static final int KEYCODE_PERIOD = 46;
static final int KEYCODE_SLASH = 47;
static final int KEYCODE_QUESTION_MARK = 47;
static final int KEYCODE_0 = 48;
static final int KEYCODE_1 = 49;
static final int KEYCODE_2 = 50;
static final int KEYCODE_3 = 51;
static final int KEYCODE_4 = 52;
static final int KEYCODE_5 = 53;
static final int KEYCODE_6 = 54;
static final int KEYCODE_7 = 55;
static final int KEYCODE_8 = 56;
static final int KEYCODE_9 = 57;
static final int KEYCODE_SEMICOLON = 59;
static final int KEYCODE_PLUS = 61;
static final int KEYCODE_EQUAL = 61;
static final int KEYCODE_A = 65;
static final int KEYCODE_B = 66;
static final int KEYCODE_C = 67;
static final int KEYCODE_D = 68;
static final int KEYCODE_E = 69;
static final int KEYCODE_F = 70;
static final int KEYCODE_G = 71;
static final int KEYCODE_H = 72;
static final int KEYCODE_I = 73;
static final int KEYCODE_J = 74;
static final int KEYCODE_K = 75;
static final int KEYCODE_L = 76;
static final int KEYCODE_M = 77;
static final int KEYCODE_N = 78;
static final int KEYCODE_O = 79;
static final int KEYCODE_P = 80;
static final int KEYCODE_Q = 81;
static final int KEYCODE_R = 82;
static final int KEYCODE_S = 83;
static final int KEYCODE_T = 84;
static final int KEYCODE_U = 85;
static final int KEYCODE_V = 86;
static final int KEYCODE_W = 87;
static final int KEYCODE_X = 88;
static final int KEYCODE_Y = 89;
static final int KEYCODE_Z = 90;
static final int KEYCODE_LEFT_BRACKET = 91;
static final int KEYCODE_BACK_SLASH = 92;
static final int KEYCODE_RIGHT_BRACKET = 93;
static final int KEYCODE_DEL = 127;
//static final int KEYCODE_MEDIA_NEXT = 87;
//static final int KEYCODE_MEDIA_PLAY_PAUSE = 85;
//static final int KEYCODE_MEDIA_PREVIOUS = 88;
static final int KEYCODE_PAGE_DOWN = 93;
static final int KEYCODE_PAGE_UP = 92;
static final int KEYCODE_PLAY = 126;
static final int KEYCODE_MEDIA_STOP = 86;
static final int KEYCODE_MEDIA_REWIND = 89;
static final int KEYCODE_MEDIA_RECORD = 130;
static final int KEYCODE_MEDIA_PAUSE = 127;
static final int KEYCODE_VOLUME_UP = 0;  // TODO
static final int KEYCODE_VOLUME_DOWN = 0; // TODO
static final int KEYCODE_MOVE_HOME = 122;
static final int KEYCODE_MOVE_END  = 123;
static final int KEYCODE_TILDE_QUOTE = 192;
static final int KEYCODE_SINGLE_QUOTE = 222;
//static final int KEYCODE_TRIGGER_PHOTO = 1000;
//static final int KEYCODE_TRIGGER_COLLAGE = 1001;

private static final int NOP = 0;
private static final int EXIT = 1;

// lastKey and lastKeyCode are handled in the draw loop
private volatile int lastKey;
private volatile int lastKeyCode;

// Processing callback when mouse key pressed
void mousePressed() {
  int button = mouseButton;
  if (DEBUGKEY) println("mousePressed()");
  if (DEBUGKEY) println("mouseButton="+mouseButton + " LEFT=" + LEFT + " RIGHT="+RIGHT+" CENTER="+CENTER);
  // ignore mouse keys when showing screen other than the camera image
  //if (legendPage >= 0 || showCameras|| review > LIVEVIEW) return;
  if (legendPage >= 0 || showCameras) return;
  if (button == LEFT) {  // remote key A
    if (review >= REVIEW && review < REVIEW_END && camera3D) {
      // print review photo
      lastKeyCode = KEYCODE_W; // print photo
    } else if (review >= REVIEW && review <= REVIEW_END) {
      // print review photo
      lastKeyCode = KEYCODE_W; // print photo
    } else {
      lastKeyCode = KEYCODE_ENTER; //KEYCODE_LEFT_BRACKET; // Photo capture
    }
  } else if (button == CENTER) {
    lastKeyCode = KEYCODE_ESC;
  } else if (button == RIGHT) {
    if (camera3D) {
      lastKeyCode = KEYCODE_A;  // toggle anaglyph live display
    } else {
      lastKeyCode = KEYCODE_RIGHT_BRACKET;  // toggle single or collage 2x2 modes
    }
  }
  if (DEBUGKEY) println("mousePressed "+button+" set lastKeyCode="+lastKeyCode);
}

// Processing call back when key released, not used
void keyReleased() {
}

// Processing call back when key pressed
void keyPressed() {
  if (DEBUGKEY) println("key="+key + " keydecimal=" + int(key) + " keyCode="+keyCode);
  //if (DEBUGKEY) Log.d(TAG, "key=" + key + " keyCode=" + keyCode);  // Android
  if (key==ESC) {
    key = 0;
    keyCode = KEYCODE_ESC;
  } else if (key == 65535 && keyCode == 0) { // special case all other keys
    // ignore key
    key = 0;
    keyCode = 0;
  }
  // save for main loop
  // we do not do any other work in this callback thread!
  lastKey = key;
  lastKeyCode = keyCode;
}

// Handling key function called from the main loop not in keyPressed()
// returns NOP on no key processed
// returns command code when a key is to be processed
int keyUpdate() {
  int cmd = NOP;  // return code

  switch(lastKeyCode) {
  case KEYCODE_Q:  // quit application gracefully
    if (DEBUG) println("Exit Program");
    if (video != null) {
      //video.stop();
      //video.dispose();
    }
    stopUDP(); // stop remote broadcast to cameras
    exit();
    break;
  case KEYCODE_ENTER:
    if (review <= LIVEVIEW) {
      if (!(legendPage >= 0 || showCameras)) {
        if (!photoBoothController.isPhotoShoot) {
          photoBoothController.tryPhotoShoot();
        }
        cmd = ENTER;
      }
    }
    break;
  case LEFT: // 3D camera adjust parallax
    horizontalOffset--;
    if (DEBUG) println("horizontalOffset="+horizontalOffset);
    break;
  case RIGHT: // 3D camera adjust parallax
    horizontalOffset++;
    if (DEBUG) println("horizontalOffset="+horizontalOffset);
    break;
  case UP:     // 3D camera adjust left and right eye vertical alignment
    verticalOffset++;
    if (DEBUG) println("verticalOffset="+verticalOffset);
    break;
  case DOWN:     // 3D camera adjust left and right eye vertical alignment
    verticalOffset--;
    if (DEBUG) println("verticalOffset="+verticalOffset);
    break;
  case KEYCODE_0: // image processing
  case KEYCODE_1:
  case KEYCODE_2:
  case KEYCODE_3:
  case KEYCODE_4:
  case KEYCODE_5:
  case KEYCODE_6:
  case KEYCODE_7:
  case KEYCODE_8:
  case KEYCODE_9:
    int index = lastKeyCode-KEYCODE_0;
    photoBoothController.setFilter(index);
    if (DEBUG) println("setFilter="+photoBoothController.getFilter());
    break;
  case KEYCODE_K:
    takePhoto(doubleTrigger, false);
    break;
  case KEYCODE_Z:
    takePhoto(doubleTrigger, true);
    break;
  case KEYCODE_F:
    focusPush();
    break;
  case KEYCODE_H:  // toggle MONO with Half width SBS
    if (screenMode == MONO_SCREEN) {
      screenMode = HWSBS_SCREEN;
    } else {
      screenMode = MONO_SCREEN;
    }
    break;
  case KEYCODE_R:
    shutterRelease();
    break;
  case KEYCODE_M:  // toggle mirror view
    mirror = !mirror;
    if (DEBUG) println("mirror="+mirror);
    break;
  case KEYCODE_A:  // anaglyph display mode
    if (camera3D) {
      anaglyph = !anaglyph;
      if (DEBUG) println("anadglyph="+anaglyph);
    }
    break;
  case KEYCODE_PLUS:  // toggle zoom image for checking focus of camera
    if (camera3D) {
      zoomPhoto = !zoomPhoto;
      if (DEBUG) println("zoomPhoto="+zoomPhoto);
    }
    break;
  case KEYCODE_MINUS:  // toggle left or right zoom image for checking focus of camera
    if (camera3D) {
      zoomPhotoIndex = (zoomPhotoIndex+1) & 1;
      if (DEBUG) println("zoomPhotoIndex="+zoomPhotoIndex);
    }
    break;
  case KEYCODE_E:  // swap left and right eye views
    if (camera3D) {
      crosseye = !crosseye;
      if (DEBUG) println("crosseye="+crosseye);
    }
    break;
  case KEYCODE_G:  // toggle stereo window pane
    if (camera3D) {
      stereoWindow = !stereoWindow;
      if (DEBUG) println("stereoWindow="+stereoWindow);
    }
    break;
  case KEYCODE_B:  // toggle save raw out of camera image
    saveRaw = !saveRaw;
    if (DEBUG) println("saveRaw="+saveRaw);
    break;
  case KEYCODE_N:  // mirror prints
    mirrorPrint = !mirrorPrint;
    if (DEBUG) println("mirrorPrint="+mirrorPrint);
    break;
  case KEYCODE_C:  // set collage 2x2 photo panel mode
    if (!camera3D) {
      review = setLiveview();
      set2x2Photo();
    }
    break;
  case KEYCODE_S:  // set single photo panel mode
    review = setLiveview();
    setSinglePhoto();
    break;
  case KEYCODE_U:  // save screenshot file
    screenshot = true;
    break;
  case KEYCODE_W:  // print file photo, must be in review mode
    if (camera3D) {
      if (review == REVIEW) {
        if (DEBUG) println("print "+ photoBoothController.getSbsFilename());
        printPhoto(photoBoothController.getSbsFilename());
      } else if (review == REVIEW_ANAGLYPH) {
        if (DEBUG) println("print "+ photoBoothController.getAnaglyphFilename());
        printPhoto(photoBoothController.getAnaglyphFilename());
      } else if (review == REVIEW_LEFT) {
        if (DEBUG) println("print "+ photoBoothController.getAnaglyphFilename());
        printPhoto(photoBoothController.getLeftFilename());
      } else if (review == REVIEW_RIGHT) {
        if (DEBUG) println("print "+ photoBoothController.getAnaglyphFilename());
        printPhoto(photoBoothController.getRightFilename());
      }
    } else {  // 2D review and collage
      if (review >= REVIEW && review <= REVIEW_END) {
        if (DEBUG) println("collage "+ review + " print "+ photoBoothController.collageFilename[review]);
        printPhoto(photoBoothController.collageFilename[review]);
      } else {
        if (DEBUG) println("print photo request out of range " + review);
      }
    }
    break;
  case KEYCODE_Y:  // double trigger delay time toggle
    if (doubleTriggerDelay != doubleTriggerDelayMax) {
      doubleTriggerDelay = doubleTriggerDelayMax;
    } else {
      doubleTriggerDelay = doubleTriggerDelayMin;
    }
    break;
  case KEYCODE_LEFT_BRACKET:
    break;
  case KEYCODE_RIGHT_BRACKET: // toggle photo panels or force 3D single panel
    review = setLiveview();
    if (camera3D) {
      setSinglePhoto();
    } else {
      togglePanelMode(); // flip between single and 2x2 photo capture panels
    }
    break;
  case KEYCODE_P:  // portrait orientation
    if (!camera3D) {
      orientation = PORTRAIT;
      if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
    }
    break;
  case KEYCODE_L:  // landscape orientation
    orientation = LANDSCAPE;
    if (DEBUG) println("orientation="+(orientation==LANDSCAPE? "Landscape":"Portrait"));
    break;
  case KEYCODE_T: // toggle mask
    if (camera3D) {
      if (review <= LIVEVIEW) { // change during live view only
        if (format == PARALLEL)
          format = STEREO_CARD;
        else
          format = PARALLEL;
      }
    } else {
      format = MONO;
    }
    break;
  case KEYCODE_TAB:
    showCameras = ! showCameras;
    if (!showCameras) clearBackground = true;
    break;
  case KEYCODE_QUESTION_MARK:
    review = setLiveview();
    if (DEBUG) println("review=OFF "+review);
    legendPage++;
    if (legendPage >= LEGENDS) {
      legendPage = -1;
    }
    break;
  case KEYCODE_SPACE:
    // Immediate capture not countdown
    photoBoothController.noCountDown = true;
    //focusPush();  // trigger Focus
    review = setLiveview();
    if (!photoBoothController.isPhotoShoot) {
      photoBoothController.tryPhotoShoot();
    }
    cmd = ENTER;
    break;
  case KEYCODE_ESC:
    if (photoBoothController.hasPreview()) {
      if (review <= LIVEVIEW)
        review = REVIEW;
      else
        // toggle review last photo or collage
        review++;

      if (camera3D) {
        // skip one of single photos left or right
        if (review == REVIEW_LEFT)  review = REVIEW_RIGHT;
        // check for end of list
        if (review >= REVIEW_END) {
          review = setLiveview();
        }
      } else {
        if (reviewNumberOfPanels == 1 ) {
          if (review > REVIEW) review = setLiveview();
        } else {  // 4 panels and collage
          if (review >= REVIEW_COLLAGE_END) {
            review = setLiveview();
          }
        }
      }
      if (DEBUG) println("ESC key review="+review);
    } else {
      //println("No images available for preview");
      setMessage("NO IMAGES", 3);
      review = setLiveview();
    }
    break;
  case KEYCODE_D: // toggle multi camera double trigger
    doubleTrigger = !doubleTrigger;
    if (DEBUG) println("multi camera double trigger="+doubleTrigger);
    break;
  default:
    break;
  }
  // clear out last keycode
  lastKey = 0;
  lastKeyCode = 0;
  return cmd;
}

int setLiveview() {
  if (camera3D) {
    if (anaglyph)
      return LIVEVIEW_ANAGLYPH;
    else
      return LIVEVIEW;
  } else {
    return LIVEVIEW;
  }
}

// toggle between single photo and collage 2x2 panel mode captures
void togglePanelMode() {
  if (numberOfPanels == 1) {
    set2x2Photo();
  } else {
    setSinglePhoto();
  }
}

// Single Photo mode
boolean setSinglePhoto() {
  boolean changed = false;
  if (numberOfPanels != 1) {
    numberOfPanels = 1;
    background(0);
    photoBoothController.updatePanelSize();
    changed = true;
  }
  return changed;
}

// Collage 2x2 Photo mode Anaglyph only
boolean set2x2Photo() {
  boolean changed = false;
  if (numberOfPanels != 4) {
    numberOfPanels = 4;
    background(0);
    photoBoothController.updatePanelSize();
    changed = true;
  }
  return changed;
}
