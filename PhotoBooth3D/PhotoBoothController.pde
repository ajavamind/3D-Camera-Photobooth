// The Photo Booth Controller sequencer for capturing our subject(s) photos
// Anaglyph only collage not tested or fully implemented

class PhotoBoothController {
  int currentState;
  PImage[] images;
  // indices for images variable:
  private static final int SBS = 0;
  private static final int ANAGLYPH = 1;
  private static final int LEFT_EYE = 2;
  private static final int RIGHT_EYE = 3;
  volatile PImage currentImage;
  volatile PImage currentRawImage;
  PImage[] collage; // print aspect ratio
  PImage collage2x2;  // not tested
  String datetime;

  String anaglyphFilename;
  String sbsFilename;
  String leftFilename;
  String rightFilename;

  boolean isPhotoShoot, endPhotoShoot;
  volatile int startPhotoShoot;
  volatile boolean noCountDown = false;
  int countInterval = 16;
  int oldShootTimeout = 4*countInterval; 
  int oldShoot = 0;
  int countdownStart = 3;

  int MAX_PANELS = 4; // 4 panels will only show anaglyph images not tested
  int PANEL_WIDTH;
  int PANEL_HEIGHT;
  int COUNTDOWN_BOX_WIDTH;
  int COUNTDOWN_BOX_HEIGHT;
  int COUNTDOWN_BOX_X;
  int COUNTDOWN_BOX_Y;
  int COUNTDOWN_TEXT_X;
  int COUNTDOWN_TEXT_Y;

  public PhotoBoothController() {
    updatePanelSize();

    COUNTDOWN_BOX_WIDTH = screenWidth/20;
    COUNTDOWN_BOX_HEIGHT = 2*screenHeight/20;
    COUNTDOWN_BOX_X = screenWidth/2-COUNTDOWN_BOX_WIDTH/2;
    COUNTDOWN_BOX_Y = screenHeight/2-COUNTDOWN_BOX_HEIGHT/2;
    COUNTDOWN_TEXT_X = screenWidth/2-COUNTDOWN_BOX_WIDTH/4;
    COUNTDOWN_TEXT_Y = screenHeight/2+COUNTDOWN_BOX_HEIGHT/4;

    currentState = 0;
    startPhotoShoot = 0;
    images = new PImage[MAX_PANELS];
    isPhotoShoot=false;
    endPhotoShoot=false;
    // save image space for panels
    for (int i=0; i<MAX_PANELS; i++) {
      images[i] = new PImage();
    }
    collage = new PImage[4];
  }

  String getLeftFilename() {
    return leftFilename;
  }

  String getRightFilename() {
    return rightFilename;
  }

  String getAnaglyphFilename() {
    return anaglyphFilename;
  }

  String getSbsFilename() {
    return sbsFilename;
  }

  // initialize counters for the controller
  void setCountInterval(int interval, int start) {
    countInterval = interval;
    oldShootTimeout = 4*countInterval; 
    oldShoot = 0;
    countdownStart = start;
  }

  void updatePanelSize() {
    if (numberOfPanels == MAX_PANELS) {
      PANEL_WIDTH = screenWidth/2;
      PANEL_HEIGHT = screenHeight/2;
    } else {
      PANEL_WIDTH = screenWidth;
      PANEL_HEIGHT = screenHeight;
    }
  }

  private void drawImage(PImage input) {
    drawImage(input, false);
  }

  private void drawImage(PImage input, boolean overrideMirror) {
    if (mirror && !overrideMirror) {
      pushMatrix();
      scale(-1, 1);
      image(input, -screenWidth, 0, screenWidth, screenHeight);
      popMatrix();
    } else {
      if (orientation == LANDSCAPE) {
        image(input, 0, 0, screenWidth, screenHeight);
      } else {
        pushMatrix();
        translate(width/2, height/2);
        rotate(-PI);
        image(input, -screenWidth/2, -screenHeight/2, screenWidth, screenHeight);
        popMatrix();
      }
    }
  }

  public boolean hasPreview() {
    if (images[PREVIEW].width == 0) {
      return false;
    }
    return true;
  }

  private void draw3DImage(PImage input, int preview, boolean overrideMirror) {
    float h ;
    float w;
    boolean OK = true;
    if (input.width == 0) {
      OK = false;
    }
    // adjust for display
    if (preview >= PREVIEW_ANAGLYPH) {
      if (screenMask) {
        h = ((float)screenWidth)/(9.0/8.0);
      } else {
        h = ((float)screenWidth)/(cameraAspectRatio/2.0);
      }
      w = (float)screenWidth;
    } else {
      h = ((float)screenWidth)/(cameraAspectRatio);
      w = (float)screenWidth;
    }
    background(0);
    if (mirror && !overrideMirror && preview == PREVIEW_OFF) {
      pushMatrix();
      scale(-1, 1);
      image(input, -screenWidth, (screenHeight-h)/2.0, w, h);
      popMatrix();
    } else {
      if (mirror && !overrideMirror && preview >= PREVIEW_ANAGLYPH) {
        pushMatrix();
        scale(-1, 1);
        if (screenWidth < screenHeight) {
          image(input, -screenWidth, (screenHeight-h)/2.0, w, h);
        } else {
          image(input, -screenWidth, (screenHeight-h), w, h);
        }
        popMatrix();
      } else {
        image(input, 0, (screenHeight-h)/2.0, w, h);
      }
    }
    if (DEBUG_ONSCREEN) {
      text("draw3DImage "+" w=" + w+ " h="+h+" preview="+preview+" override="+overrideMirror, 20, height/2);
      text("draw3DImage "+ " anaglyph="+anaglyph+ " mirror="+mirror, 20, height/2+40);
    }
    if (!OK) {
      fill(128);
      text("NO IMAGES", width/4, height/2);
      println("NO IMAGES");
      preview = PREVIEW_END;
    }
  }

  public void drawPrevious() {
    if (DEBUG) println("drawPrevious() currentState="+currentState);
    if (camera3D) {
      draw3DImage(images[currentState], PREVIEW_OFF, true);
    } else {
      drawImage(images[currentState], true);
    }
  }

  public void drawLast() {
    if (numberOfPanels == 1) {
      if (images[SBS] != null) {
        //if (DEBUG) println("drawLast() preview="+preview);
        if (camera3D) {
          draw3DImage(images[preview], preview, true);
        } else {
          drawImage(images[SBS]);
        }
      } else {
        fill(255);
        text("NO IMAGES", screenWidth/4, screenHeight);
      }
    } else {
      if (collage2x2 != null) {
        float bw = (cameraWidth-(cameraHeight/printAspectRatio))/2.0;
        int sx = int(bw);
        image(collage2x2, sx/2, 0, collage2x2.width/4, collage2x2.height/4);
      }
    }
  }

  public void drawMask() {
    if (camera3D) {
      draw3DMaskForScreen(printAspectRatio); // mask off screen to show print view
    } else {
      drawMaskForScreen(printAspectRatio); // mask off screen to show print view
    }
  }

  public void drawCurrent() {
    if (camera3D) {
      if (anaglyph) {
        draw3DImage(currentImage, PREVIEW_ANAGLYPH, false);
      } else {
        draw3DImage(currentImage, PREVIEW_OFF, false);
      }
    } else {
      drawImage(currentImage);
    }
    drawMask();
  }

  public void oldShoot() {
    if (oldShoot > oldShootTimeout) {
      tryPhotoShoot();
    }
    oldShoot++;
  }

  public void processImage(PImage input) {
    if (input == null) return;  // null when still initializing
    currentRawImage = input.get();
    currentImage = imageProcessor.processImage(currentRawImage);
    if (camera3D) {
      if (anaglyph) {  //check for anaglyph because aspect ratio reduced
        draw3DImage(currentImage, PREVIEW_ANAGLYPH, false);
      } else {
        draw3DImage(currentImage, PREVIEW_OFF, false);
      }
    } else {
      drawImage(currentImage);
    }
    drawMask();
  }

  public void tryPhotoShoot() {
    if (!isPhotoShoot) startPhotoShoot();
    else {
      endPhotoShoot = false;
      isPhotoShoot = false;
      background(0);
    }
  }

  public void startPhotoShoot() {
    if (isPhotoShoot) return; // return when already in countdown shoot mode
    isPhotoShoot = true;
    startPhotoShoot = 0;
  }

  public void endPhotoShoot() {
    endPhotoShoot = true;
    oldShoot = 0;
    if (DEBUG) println("endPhotoShoot drawPrevious()");
    drawPrevious();
  }

  // draw photo shoot count down digits
  public void drawPhotoShoot() {
    background(0);
    int digit = getCountDownDigit(countdownStart, countInterval);
    if (digit > 0 && !endPhotoShoot) {
      drawCurrent();
      fill(0x80FFFF80);
      textSize(largeFontSize);
      String digitS = str(digit);
      float tw = textWidth(digitS);
      float th = largeFontSize/2;
      if (orientation == LANDSCAPE) {
        pushMatrix();
        translate(screenWidth/2, screenHeight/2+th);
        text(digitS, -tw/2, 0);
        popMatrix();
      } else {
        pushMatrix();
        translate(screenWidth/2+th, screenHeight/2);
        rotate(-HALF_PI);
        text(digitS, -tw/2, 0);
        popMatrix();
      }
      textSize(fontSize);
      fill(255);
    } else if (digit == 0) {
      drawCurrent();
      fill(0x80FFFF80);
      textSize(largeFontSize);
      String digitS = finalCountdownText;
      float tw = textWidth(digitS);
      float th = largeFontSize/2;
      if (orientation == LANDSCAPE) {
        pushMatrix();
        translate(screenWidth/2, screenHeight/2+th);
        text(digitS, -tw/2, 0);
        popMatrix();
      } else {
        pushMatrix();
        translate(screenWidth/2+th, screenHeight/2);
        rotate(-HALF_PI);
        text(digitS, -tw/2, 0);
        popMatrix();
      }
      focusPush();  // trigger Focus
      textSize(fontSize);
      fill(255);
    } else if (digit == -1) {
      // flash screen and take photo
      background(0);
      takePhoto(doubleTrigger, false);  // take photo
      boolean done = incrementState();
      if (done) {
        drawPrevious();
        String saved = "Saved "+datetime;
        float tw = textWidth(saved);

        if (orientation == LANDSCAPE) {
          pushMatrix();
          translate(screenWidth/2, screenHeight/24);
          text(saved, -tw/2, 0);
          popMatrix();
        } else {
          float angleText = radians(270);
          pushMatrix();
          //translate(screenWidth/2, screenHeight/2);
          translate(screenWidth/32, screenHeight/2+tw/2);
          rotate(angleText);
          text(saved, 0, 0);
          popMatrix();
        }
        if (numberOfPanels == 4) {
          if (DEBUG) println("save collage2x2 " + datetime);
          PGraphics pg = saveCollage(collage, OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime, fileType);
          collage2x2 = pg.copy();
          pg.dispose();
          drawCollage(collage2x2);
        }
        drawMask();
      }
      startPhotoShoot=0;
    }
    startPhotoShoot++;
  }

  // not tested
  void drawCollage(PImage img) {
    if (img != null) {
      float bw = (screenWidth-(screenHeight/printAspectRatio))/2.0;
      int sx = int(bw);
      //image(collage2x2, sx/2, 0, collage2x2.width/4, collage2x2.height/4);
      image(img, sx, 0, img.width/(2*cameraHeight/screenHeight), img.height/(2*cameraHeight/screenHeight));
    }
  }

  int getCountDownDigit(int initial, int photoDelay) {
    int cdd = -1; // count down digit value
    int aDelay = photoDelay/4;
    if (numberOfPanels == 4) {  // not tested
      aDelay = photoDelay/4;
    }
    if (!anaglyph) aDelay = photoDelay/2; // anaglyph processing slows down count, so compensate
    if (startPhotoShoot < aDelay) {
      cdd = initial;
    } else if (startPhotoShoot >= aDelay && startPhotoShoot < 2*aDelay) {
      cdd = initial-1;
    } else if (startPhotoShoot >= 2*aDelay && startPhotoShoot < 3*aDelay) {
      cdd = initial-2;
    } else if (startPhotoShoot >= 3*aDelay && startPhotoShoot < 4*aDelay) {
      cdd = initial-3;
    } else if (startPhotoShoot >= 4*aDelay) {
      cdd = initial-4;
    }
    if (noCountDown) {
      noCountDown = false;
      startPhotoShoot = 4*aDelay;
      cdd = initial-3;
    }
    if (DEBUG) println("countDownCounter="+cdd + " aDelay="+aDelay + " startPhotoShoot="+startPhotoShoot);
    return cdd;
  }

  public void setFilter(int num) {
    imageProcessor.filterNum = num;
  }

  public int getFilter() {
    return imageProcessor.filterNum;
  }

  public boolean incrementState() {
    boolean done = false;
    images[currentState] = currentImage.get();
    if (currentState == 0) {
      datetime = getDateTime();
    }
    if (saveRaw) {
      if (DEBUG) println("save unfiltered photo from camera"+ currentState + " " + datetime);
      if (camera3D) {
        saveRaw3DImage(currentRawImage, currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime, rawFileType);
      } else {
        saveImage(currentRawImage, currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime, fileType);
      }
    }
    if (camera3D) {
      if (DEBUG) println("save filter "+ imageProcessor.filterNum + " or offset photo "+ (currentState+1) + " " + datetime);
      if (anaglyph) {
        save3DImage(currentRawImage, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
      } else {
        save3DImage(currentImage, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
      }
    } else {
      if (DEBUG) println("save 2D photo "+ (currentState+1) + " " + datetime);
      saveImage(images[currentState], currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
    }
    currentState += 1;
    if (currentState >= numberOfPanels) {
      done = true;
      currentState=0;
      endPhotoShoot();
    }
    return done;
  }

  // Save images from 2D cameras
  public void saveImage(PImage img, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    // crop and save
    collage[index] = cropForPrint(img, printAspectRatio);  // adjusts for mirror
    filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_cr"+ "." + filetype;
    collage[index].save(filename);
    if (orientation == PORTRAIT) {
      setEXIF(filename);
    }
  }

  // save images from 3D cameras
  public void saveRaw3DImage(PImage img, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    // crop and save
    filename = outputFolderPath + File.separator + outputFilename + suffix + "_Raw" + "." + filetype;
    img.save(filename);
  }

  // save images from 3D cameras
  public void save3DImage(PImage img, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    if (DEBUG) println("save3DImage ");

    images[SBS] = mirror3D(img, mirror);
    filename = outputFolderPath + File.separator + outputFilename + suffix + "_2x1"+ "." + filetype;
    images[SBS] = imageProcessor.alignSBS(images[SBS], horizontalOffset, verticalOffset, mirror);
    if (screenMask) {
      images[SBS] = cropForMaskPrint(images[SBS], printAspectRatio);
    }
    images[SBS].save(filename);  // save SBS image
    sbsFilename = filename;

    // split 3D Side-by-side image into left and right images and adjust vertical and horizontal offsets
    saveSplitImage(images[SBS], outputFolderPath, outputFilename, suffix, filetype);

    // create anaglyph image from left and right saved image
    images[ANAGLYPH] = imageProcessor.colorAnaglyph(images[LEFT_EYE], images[RIGHT_EYE], 0, 0);
    filename = outputFolderPath + File.separator + outputFilename + suffix + "_ana"+ "." + filetype;
    images[ANAGLYPH].save(filename);
    anaglyphFilename = filename;
  }

  // crop for mask printing
  PImage cropForMaskPrint(PImage src, float printAspectRatio) {
    if (DEBUG) println("cropForMaskPrint print AR="+printAspectRatio);
    if (DEBUG) println("cropForMaskPrint image width="+src.width + " height="+src.height);
    float AR = 8.0/9.0;  // crop aspect ratio
    // create a new PImage
    float bw = (src.width-(src.height/AR/2.0))/2.0; // pixel width for one eye view
    if (DEBUG) println("bw="+bw);
    int iw = int(bw/2);
    int sx = ((src.width/2)-iw)/2;
    int sy = 0;
    int sw = iw;
    int sh = src.height;
    int dx = 0;
    int dy = 0;
    int dw = sw;
    int dh = src.height;
    PImage img = createImage(2*dw, dh, RGB);
    if (DEBUG) println(" sx="+sx+" sy="+sy+" sw="+sw+" sh="+sh +" dx="+dx+" dy="+dy+" dw="+dw+" dh="+dh);
    img.copy(src, sx, sy, sw, sh, dx, dy, dw, dh);  // cropped left eye copy
    sx = sx + src.width/2;
    dx = dx + iw;
    if (DEBUG) println(" sx="+sx+" sy="+sy+" sw="+sw+" sh="+sh +" dx="+dx+" dy="+dy+" dw="+dw+" dh="+dh);
    img.copy(src, sx, sy, sw, sh, dx, dy, dw, dh);  // cropped right eye copy
    return img;
  }

  // crop for printing 2D photo or 2D collage
  PImage cropForPrint(PImage src, float printAspectRatio) {
    if (DEBUG) println("cropForPrint "+printAspectRatio+ " mirrorPrint="+mirrorPrint+" " +(orientation==LANDSCAPE? "Landscape":"Portrait"));
    // first crop creating a new PImage
    float bw = (cameraWidth-(cameraHeight/printAspectRatio))/2.0;
    int sx = int(bw);
    int sy = 0;
    int sw = cameraWidth-int(2*bw);
    int sh = cameraHeight;
    int dx = 0;
    int dy = 0;
    int dw = sw;
    int dh = cameraHeight;
    PImage img = createImage(dw, dh, RGB);
    img.copy(src, sx, sy, sw, sh, dx, dy, dw, dh);  // cropped copy
    // next mirror image if needed
    if (mirrorPrint && orientation == PORTRAIT) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(0);
      pg.pushMatrix();
      pg.scale(-1, 1);
      pg.image(img, -dw, 0, dw, dh);  // horizontal flip
      pg.popMatrix();
      pg.endDraw();
      //img = pg.copy();
      //pg.dispose();
      img = pg;
    } else if (!mirrorPrint && orientation == PORTRAIT) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(0);
      pg.pushMatrix();
      pg.translate(dw/2, dh/2);
      pg.rotate(PI);
      pg.image(img, -dw/2, -dh/2, dw, dh);  // rotate -180
      pg.popMatrix();
      pg.endDraw();
      //img = pg.copy();
      //pg.dispose();
      img = pg;
    } else if (mirrorPrint && orientation == LANDSCAPE) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(0);
      pg.pushMatrix();
      pg.scale(-1, 1);
      pg.image(img, -dw, 0, dw, dh);  // horizontal flip
      pg.popMatrix();
      pg.endDraw();
      //img = pg.copy();
      //pg.dispose();
      img = pg;
    }
    return img;
  }

  // draw mask for screen to match print image aspect ratio
  // 4x6 print aspect ratio
  void drawMaskForScreen( float printAspectRatio) {
    if (!screenMask) return;
    float x = 0;
    float y = 0;
    float w = (screenWidth-(screenHeight/printAspectRatio))/2.0;
    float h = screenHeight;
    fill(0);
    if (numberOfPanels == 4) {
      stroke(128);
    } else {
      stroke(0);
    }
    rect(x, y, w, h);  // left side
    rect(screenWidth-w, y, w, h);  // right side
    fill(128);

    // check for collage mode
    if (numberOfPanels == 4) {
      // draw collage position and count
      float angleText = 0;
      float tw;
      noFill();
      stroke(128);
      float xt = 0;
      float yt = 0;
      pushMatrix();
      if (orientation == LANDSCAPE) {
        xt = screenWidth-w;
        yt = w/2;
      } else {
        xt = w/2;
        yt = w-w/4;
        angleText = radians(270);
      }
      translate(xt, yt);
      rotate(angleText);
      text(" "+str(photoBoothController.currentState+1)+"/"+str(numberOfPanels), 0, 0);
      popMatrix();

      // drawing collage matrix
      strokeWeight(4);
      if (orientation == LANDSCAPE) {
        rect(0, 0, w, w);  // square
        fill(128);
        rect(0, w/2, w, 2); // horizontal line
        rect(w/2, 0, 2, w);  // vertical line
        switch(photoBoothController.currentState) {
        case 0:
          circle(w/4, w/2-w/4, w/4);
          break;
        case 1:
          circle(w/4+w/2, w/2-w/4, w/4);
          break;
        case 2:
          circle(w/4, w/2+w/4, w/4);
          break;
        case 3:
          circle(w/4+w/2, w/2+w/4, w/4);
          break;
        }
      } else {
        rect(0, h-w, w, w);  // square
        fill(255);
        rect(0, h-w/2, w, 2); // horizontal line
        rect(w/2, h-w, 2, w);  // vertical line
        switch(photoBoothController.currentState) {
        case 1:
          circle(w/4, h-w/2-w/4, w/4);
          break;
        case 3:
          circle(w/4+w/2, h-w/2-w/4, w/4);
          break;
        case 0:
          circle(w/4, h-w/2+w/4, w/4);
          break;
        case 2:
          circle(w/4+w/2, h-w/2+w/4, w/4);
          break;
        }
      }
    } else {
    }
  }

  // draw mask for screen to match print image aspect ratio
  // 4x6 print aspect ratio
  void draw3DMaskForScreen( float printAspectRatio) {
    if (!screenMask) return;
    fill(0);
    float x = 0;
    float y = 0;
    float w = 0;
    float h = 0;
    w = (screenWidth-(screenHeight/printAspectRatio/2.0))/2.0;

    h = screenHeight;
    if (anaglyph) {
      rect(x, y, w, h);  // left side
      rect(screenWidth-w, y, w, h);  // right side
    } else {
      w = w/2.0;
      rect(0, y, w, h);  // left side
      rect(screenWidth/2-w, y, w, h);  // left side
      rect(screenWidth/2, y, w, h);  // right side
      rect(screenWidth-w, y, w, h);  // right side
    }
    fill(128);
    //println("w="+w+" h="+h);
  }

  void saveSplitImage(PImage photo, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    if (photo == null) return;
    int w = photo.width/2;
    int h = photo.height;

    // split into two files, save in images[2] images[3]
    PImage left = createImage(w, h, RGB);
    PImage right = createImage(w, h, RGB);
    left.copy(photo, 0, 0, w, h, 0, 0, w, h);
    images[LEFT_EYE] = left;

    filename = outputFolderPath + File.separator + outputFilename + suffix + "_l"+ "." + filetype;
    images[LEFT_EYE].save(filename);
    leftFilename =  filename;
    right.copy(photo, w, 0, w, h, 0, 0, w, h);
    images[RIGHT_EYE] = right;
    filename = outputFolderPath + File.separator + outputFilename + suffix + "_r"+ "." + filetype;
    images[RIGHT_EYE].save(filename);
    rightFilename = filename;
  }

  // Save composite collage from original photos
  // images input already cropped
  PGraphics saveCollage(PImage[] collage, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    PGraphics pg;
    int w = int(cameraHeight/printAspectRatio);
    int h = cameraHeight;
    pg = createGraphics(2*w, 2*h);
    pg.beginDraw();
    pg.background(0);
    pg.fill(255);
    // build collage
    if (orientation == LANDSCAPE) {
      for (int i=0; i<numberOfPanels; i++) {
        switch (i) {
        case 0:
          pg.image(collage[i], 0, 0, w, h);
          break;
        case 1:
          pg.image(collage[i], w, 0, w, h);
          break;
        case 2:
          pg.image(collage[i], 0, h, w, h);
          break;
        case 3:
          pg.image(collage[i], w, h, w, h);
          break;
        default:
          break;
        }
      }
    } else { // portrait
      for (int i=0; i<numberOfPanels; i++) {
        switch (i) {
        case 1:
          pg.image(collage[i], 0, 0, w, h);
          break;
        case 3:
          pg.image(collage[i], w, 0, w, h);
          break;
        case 0:
          pg.image(collage[i], 0, h, w, h);
          break;
        case 2:
          pg.image(collage[i], w, h, w, h);
          break;
        default:
          break;
        }
      }
    }

    // draw dividers
    pg.rect(0, h-dividerSize/2, 2*w, dividerSize);
    pg.rect(w-dividerSize/2, 0, dividerSize, 2*h);
    pg.endDraw();
    String filename = outputFolderPath + File.separator + outputFilename + suffix + "_" + number(5) + "_cr"+ "." + filetype;
    pg.save(filename);
    if (orientation == PORTRAIT) {
      setEXIF(filename);
    }
    return pg;
  }

  // duplicate and mirror 3D image
  // swaps left and right image as side affect
  PImage mirror3D(PImage src, boolean mirror) {
    PImage img;
    int dw = src.width;
    int dh = src.height;

    PGraphics pg;
    pg = createGraphics(dw, dh);
    pg.beginDraw();
    pg.background(0);
    pg.pushMatrix();
    if (mirror) {
      pg.scale(-1, 1);
      pg.image(src, -dw, 0, dw, dh);  // horizontal flip
    } else {
      pg.image(src, 0, 0, dw, dh);  // no flip
    }
    pg.popMatrix();
    pg.endDraw();
    img = pg.copy();
    pg.dispose();
    return img;
  }

  // creates image for printing as a stereo card for 4x6 printer
  // src is camera image with camera width and height
  void save3Dprint(PImage src, float printAspectRatio, String filename) {
    PImage img;
    int dw = src.width;
    int dh = int(((float) dw)*printAspectRatio);
    int dx = 0;
    int dy = (dh-src.height)/2;
    if (DEBUG) println("src.width="+src.width + " src.height="+src.height + " dx="+dx+" dy="+dy+" dw="+dw+" dh="+dh);
    // TODO add print information in stereo text
    PGraphics pg;
    pg = createGraphics(dw, dh);
    pg.beginDraw();
    pg.background(color(255, 255, 255, 255));
    pg.image(src, dx, dy, src.width, src.height);
    pg.endDraw();
    img = pg.copy();
    img.save(filename);
    if (DEBUG) println("3D print: "+filename);
    pg.dispose();
  }
}
