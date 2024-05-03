// The Photo Booth Controller sequencer for capturing our subject(s) photos
// Anaglyph only collage not tested or fully implemented

import java.util.Timer;
import java.util.TimerTask;

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

  boolean isPhotoShoot;
  boolean endPhotoShoot;
  volatile boolean noCountDown = false;

  int oldShootTimeout = 64;  // number of sketch frames to draw last photo just taken
  int oldShootCounter = 0; // frame counter for keeping photo taken on screen during draw()
  int countdownStart = 3;
  int countdownDigit = -1;

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
  void setCountdownStart(int start) {
    oldShootCounter = 0;
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
    if (images[REVIEW] != null && images[REVIEW].width == 0) {
      return false;
    }
    return true;
  }

  private void draw3DImage(PImage img, int review, boolean overrideMirror) {
    float hImg= img.height;
    float wImg = img.width;
    float arImg = wImg/hImg;  // aspect ratio of image
    float hScreen = (float) screenHeight;
    float wScreen = (float) screenWidth;
    float h = 0;
    float w = 0;
    float hOffset = 0;
    boolean OK = true;
    if (img.width == 0) {
      OK = false;
    }
    // adjust for display
    if (format == STEREO_CARD) {
      if (review == REVIEW) { // is a SBS 3D saved image
        h = wScreen / (cameraAspectRatio/2.0);
        w = wScreen;
      } else if (review >= REVIEW_ANAGLYPH) { // is a 2D saved image
        h = hScreen;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      } else { // is a 3D SBS live image
        h = wScreen / (cameraAspectRatio);
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      }
    } else {
      if (review == REVIEW) { // is a SBS 3D saved image
        h = wScreen / arImg;
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      } else if (review >= REVIEW_ANAGLYPH) {  // is a 2D saved image
        //h = (wScreen)/(cameraAspectRatio/2.0);
        h = hScreen ;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      } else {  // is a 3D SBS live image
        h = wScreen / (cameraAspectRatio);
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      }
    }
    background(0);
    if (mirror && !overrideMirror && review == LIVEVIEW) {
      pushMatrix();
      scale(-1, 1);
      image(img, -screenWidth+hOffset, (screenHeight-h)/2.0, w, h);
      popMatrix();
    } else {
      if (mirror && !overrideMirror && review >= REVIEW_ANAGLYPH) {
        pushMatrix();
        scale(-1, 1);
        if (screenWidth < screenHeight) {
          image(img, -screenWidth+hOffset, (screenHeight-h)/2.0, w, h);
        } else {
          image(img, -screenWidth+hOffset, (screenHeight-h), w, h);
        }
        popMatrix();
      } else {
        image(img, hOffset, (screenHeight-h)/2.0, w, h);
      }
    }
    if (DEBUG_ONSCREEN) {
      fill(255);
      text("draw3DImage image "+" w=" + wImg+ " h="+hImg+" arImg="+arImg, 20, height/2-40);
      text("draw3DImage "+" w=" + w+ " h="+h+" review="+review+" override="+overrideMirror, 20, height/2);
      text("draw3DImage "+ " anaglyph="+anaglyph+ " mirror="+mirror, 20, height/2+40);
    }
    if (!OK) {
      fill(128);
      text("NO IMAGES", width/4, height/2);
      println("NO IMAGES");
      review = REVIEW_END;
    }
  }

  private void draw3DliveviewImage(PImage img, int review) {
    float hImg= img.height;
    float wImg = img.width;
    float arImg = wImg/hImg;  // aspect ratio of image
    float hScreen = (float) screenHeight;
    float wScreen = (float) screenWidth;
    float h = 0;
    float w = 0;
    float hOffset = 0;
    // adjust for display
    if (format == STEREO_CARD) {
      if (review == LIVEVIEW_ANAGLYPH) { // is a 2D saved image
        h = hScreen;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      } else { // is a 3D SBS live image
        h = wScreen / (cameraAspectRatio);
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      }
    } else {
      if (review == LIVEVIEW_ANAGLYPH) {  // is a 2D saved image
        h = hScreen ;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      } else {  // is a 3D SBS live image
        h = wScreen / (cameraAspectRatio);
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      }
    }
    background(0);
    if (mirror && review == LIVEVIEW) {
      pushMatrix();
      scale(-1, 1);
      image(img, -screenWidth+hOffset, (screenHeight-h)/2.0, w, h);
      popMatrix();
    } else {
      if (mirror && review == LIVEVIEW_ANAGLYPH) {
        pushMatrix();
        scale(-1, 1);
        if (screenWidth < screenHeight) {
          image(img, -screenWidth+hOffset, (screenHeight-h)/2.0, w, h);
        } else {
          image(img, -screenWidth+hOffset, (screenHeight-h), w, h);
        }
        popMatrix();
      } else {
        image(img, hOffset, (screenHeight-h)/2.0, w, h);
      }
    }
    if (DEBUG_ONSCREEN) {
      fill(255);
      text("draw3DImage image "+" w=" + wImg+ " h="+hImg+" arImg="+arImg, 20, height/2-40);
      text("draw3DImage "+" w=" + w+ " h="+h+" review="+review, 20, height/2);
      text("draw3DImage "+ " anaglyph="+anaglyph+ " mirror="+mirror, 20, height/2+40);
    }
  }

  private void draw3DreviewImage(PImage img, int index) {
    float hImg= img.height;
    float wImg = img.width;
    float arImg = wImg/hImg;  // aspect ratio of image
    float hScreen = (float) screenHeight;
    float wScreen = (float) screenWidth;
    float h = 0;
    float w = 0;
    float hOffset = 0;

    // adjust for display
    if (format == STEREO_CARD) {
      if (index == REVIEW) { // is a SBS 3D saved image
        h = hScreen;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      } else if (index >= REVIEW_ANAGLYPH) { // is a 2D saved image
        h = hScreen;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      }
    } else {
      if (index == REVIEW) { // is a SBS 3D saved image
        h = wScreen / arImg;
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      } else if (index >= REVIEW_ANAGLYPH) {  // is a 2D saved image
        h = hScreen ;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      }
    }
    background(0);
    image(img, hOffset, (screenHeight-h)/2.0, w, h);
    if (DEBUG_ONSCREEN) {
      fill(255);
      text("draw3DImage image "+" w=" + wImg+ " h="+hImg+" arImg="+arImg, 20, height/2-40);
      text("draw3DImage "+" w=" + w+ " h="+h+" review="+index, 20, height/2);
      text("draw3DImage "+ " anaglyph="+anaglyph+ " mirror="+mirror, 20, height/2+40);
    }
  }

  // draw previous is photo just taken, not in review mode
  public void drawPrevious() {
    if (DEBUG) println("drawPrevious() currentState="+currentState);
    if (camera3D) {
      //draw3DreviewImage(images[currentState], REVIEW);
      if (anaglyph)
        draw3DreviewImage(images[REVIEW_ANAGLYPH], REVIEW_ANAGLYPH);
      else
        draw3DreviewImage(images[currentState], REVIEW);
    } else {
      drawImage(images[currentState], true);
    }
  }

  public void drawLast() {
    if (numberOfPanels == 1) {
      if (images[SBS] != null) {  // check that images have been saved for review
        if (camera3D) {
          draw3DreviewImage(images[review], review);
        } else {
          drawImage(images[SBS]);
        }
      } else {
        fill(255);
        text("NO IMAGES", screenWidth/4, screenHeight);
      }
    } else { // collage not tested for 3D mode TODO
      if (collage2x2 != null) {
        float bw = (cameraWidth-(cameraHeight*printAspectRatio))/2.0;
        int sx = int(bw);
        image(collage2x2, sx/2, 0, collage2x2.width/4, collage2x2.height/4);
      }
    }
  }

  public void drawMask() {
    if (camera3D) {
      draw3DMaskForScreen(); // mask off screen to show print view
    } else {
      drawMaskForScreen(printAspectRatio); // mask off screen to show print view
    }
  }

  public void drawCurrent() {
    if (camera3D) {
      if (anaglyph) {
        draw3DliveviewImage(currentImage, LIVEVIEW_ANAGLYPH);
      } else {
        draw3DliveviewImage(currentImage, LIVEVIEW);
      }
    } else {
      drawImage(currentImage);
    }
    drawMask();
  }

  // show last photo taken for a short time
  // variable oldShootCounter is a frame counter for draw()
  public void lastPhoto() {
    if (oldShootCounter > oldShootTimeout) {
      tryPhotoShoot();
    }
    oldShootCounter++;
  }

  public void tryPhotoShoot() {
    if (!isPhotoShoot) startPhotoShoot(countdownStart);
    else {
      endPhotoShoot = false;
      isPhotoShoot = false;
      background(0);
    }
  }

  public void processImage(PImage input) {
    if (input == null) return;  // null when still initializing
    currentRawImage = input.get();
    currentImage = imageProcessor.processImage(currentRawImage);
    if (camera3D) {
      if (anaglyph) {  //check for anaglyph because aspect ratio reduced
        draw3DliveviewImage(currentImage, LIVEVIEW_ANAGLYPH);
      } else {
        draw3DliveviewImage(currentImage, LIVEVIEW);
      }
    } else {
      drawImage(currentImage);
    }
    drawMask();
  }

  public void startPhotoShoot(int start) {
    if (isPhotoShoot) return; // return when already in countdown shoot mode
    isPhotoShoot = true;
    countdownDigit = start+1;
    if (noCountDown) {
      noCountDown = false;
      countdownDigit = 1; // smile only before shutter
    }

    Timer timer = new Timer();
    // define a task to decrement the countdown digit every second
    TimerTask task = new TimerTask() {
      public void run() {
        countdownDigit--;
        if (countdownDigit < 0) {
          // stop the timer when the countdown reaches 0
          timer.cancel();
        }
      }
    };
    // start the timer
    timer.scheduleAtFixedRate(task, 0, 1000);
  }

  public void endPhotoShoot() {
    endPhotoShoot = true;
    oldShootCounter = 0;
    if (DEBUG) println("endPhotoShoot drawPrevious()");
    drawPrevious();
  }

  // draw photo shoot count down digits
  public void drawCountdownSequence() {
    background(0);
    int digit = getCountDownDigit();
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
      }
    }
  }

  // not tested for 3D
  void drawCollage(PImage img) {
    if (img != null) {
      float bw = (screenWidth-(screenHeight*printAspectRatio))/2.0;
      int sx = int(bw);
      //image(collage2x2, sx/2, 0, collage2x2.width/4, collage2x2.height/4);
      image(img, sx, 0, img.width/(2*cameraHeight/screenHeight), img.height/(2*cameraHeight/screenHeight));
    }
  }

  int getCountDownDigit() {
    return countdownDigit;
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
    filename = outputFolderPath + File.separator + outputFilename + suffix + "_2x1"+ "." + filetype;
    if (!mirrorPrint && mirror) {
      images[SBS] = mirror3D(img, false);
      images[SBS] = imageProcessor.alignSBS(images[SBS], horizontalOffset, verticalOffset, false);
    } else {
      images[SBS] = mirror3D(img, mirror);
      images[SBS] = imageProcessor.alignSBS(images[SBS], horizontalOffset, verticalOffset, mirror);
    }
    if (format == STEREO_CARD) {
      images[SBS] = cropFor3DMaskPrint(images[SBS], printAspectRatio);
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

  // crop for 3D mask printing
  PImage cropFor3DMaskPrint(PImage src, float printAspectRatio) {
    if (DEBUG) println("cropFor3DMaskPrint print AR="+printAspectRatio);
    if (DEBUG) println("cropFor3DMaskPrint image width="+src.width + " height="+src.height);
    // create a new PImage
    float bw = (printPxWidth); // pixel width for printer at 300 dpi
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
    int dd = (printPxHeight-dh)/2;
    PImage img;
    PGraphics pg = createGraphics(printPxWidth, printPxHeight);
    if (DEBUG) println(" sx="+sx+" sy="+sy+" sw="+sw+" sh="+sh +" dx="+dx+" dy="+dy+" dw="+dw+" dh="+dh);
    //img.copy(src, sx, sy, sw, sh, dx, dy, dw, dh);  // cropped left eye copy
    pg.beginDraw();
    pg.background(255); // white
    pg.copy(src, sx, sy, sw, sh, dx, dy+dd, dw, dh);  // cropped left eye copy
    sx = sx + src.width/2;
    dx = dx + iw;
    if (DEBUG) println(" sx="+sx+" sy="+sy+" sw="+sw+" sh="+sh +" dx="+dx+" dy="+dy+" dw="+dw+" dh="+dh);
    pg.copy(src, sx, sy, sw, sh, dx, dy+dd, dw, dh);  // cropped right eye copy

    // draw header and footer text
    // header
    pg.fill(0);  // black text
    pg.textSize(fontSize);
    String headerText = eventText;
    float hw = round(((printPxWidth/2)-pg.textWidth(headerText))/2.0);
    if (DEBUG) println("hw="+hw);
    pg.text(headerText, hw, fontSize );
    pg.text(headerText, dx + hw, fontSize );

    // footer
    pg.fill(0);  // black text
    pg.textSize(fontSize);
    String footerText = titleText;
    float fw = round(((printPxWidth/2)-pg.textWidth(footerText))/2.0);
    if (DEBUG) println("fw="+fw);
    pg.text(footerText, fw, dh + dd + fontSize );
    pg.text(footerText, dx + fw, dh + dd + fontSize );
    pg.endDraw();

    img = pg.copy();
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

  // 2D camera
  // draw mask for screen to match print image aspect ratio
  // 4x6 print aspect ratio
  void drawMaskForScreen( float printAspectRatio) {
    if (format != STEREO_CARD) return;
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
  void draw3DMaskForScreen() {
    if (format != STEREO_CARD) return;
    fill(0);
    float x = 0;
    float y = 0;
    float w = 0;
    float h = 0;
    //w = (screenWidth-(screenHeight*printAspectRatio)/2.0)/2.0;
    w = (screenWidth-(printPxWidth)/2.0)/2.0;
    h = screenHeight;
    //println("w="+w+" h="+h);

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
  // not tested TODO
  PGraphics saveCollage(PImage[] collage, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    PGraphics pg;
    int w = int(cameraHeight*printAspectRatio);
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
    int dh = int(((float) dw)/printAspectRatio);
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
