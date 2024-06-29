// The Photo Booth Controller sequencer for capturing our subject(s) photos
// 3D Anaglyph only 2x2 collage is not implemented

import java.util.Timer;
import java.util.TimerTask;

class PhotoBoothController {
  volatile int currentState;
  PImage[] images;
  // indices for images variable:
  private static final int SBS = 0;
  private static final int ANAGLYPH = 1;
  private static final int LEFT_EYE = 2;
  private static final int RIGHT_EYE = 3;
  volatile PImage currentImage;
  volatile PImage currentRawImage;
  volatile PImage[] collage;
  String datetime;
  Timer countdownTimer;

  String anaglyphFilename;
  String sbsFilename;
  String leftFilename;
  String rightFilename;

  volatile boolean isPhotoShoot;
  volatile boolean endPhotoShoot;
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
    collage = new PImage[5]; // 4 panels + collage image
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
    float imgAR = (float) input.width/ (float)input.height;
    if (mirror && !overrideMirror) {
      pushMatrix();
      scale(-1, 1);
      image(input, -screenWidth+(screenWidth-screenHeight*imgAR)/2, 0, screenHeight*imgAR, screenHeight);
      popMatrix();
    } else {
      if (orientation == LANDSCAPE) {
        image(input, (screenWidth-screenHeight*imgAR)/2, 0, screenHeight*imgAR, screenHeight);
      } else {
        pushMatrix();
        translate(width/2, height/2);
        rotate(-PI);
        image(input, -screenWidth/2+(screenWidth-screenHeight*imgAR)/2, -screenHeight/2, screenHeight*imgAR, screenHeight);
        popMatrix();
      }
    }
  }

  public boolean hasPreview() {
    if (images[REVIEW] == null || images[REVIEW].width == 0) {
      return false;
    }
    return true;
  }

  private void draw3DliveviewImage(PImage img, int index) {
    if (img == null) return;
    if (index == LIVEVIEW) {
      setDisplayImage(img, index);
    }
    float hImg= img.height;
    float wImg = img.width;
    float arImg = wImg/hImg;  // aspect ratio of image
    float hScreen = (float) screenHeight;
    float wScreen = (float) screenWidth;
    float h = 0;
    float w = 0;
    float hOffset = 0;
    float vOffset = 0;
    // adjust for display
    if (format == STEREO_CARD) {
      if (index == LIVEVIEW_ANAGLYPH) { // check for 2D anaglyph image
        h = hScreen;
        w = hScreen * arImg;
        hOffset = (wScreen - w)/2.0;
      } else { // is a 3D SBS live image // TODO fill screen instead of trimming
        //println(" stereo card");
        h = wScreen / (cameraAspectRatio);
        w = wScreen;
        hOffset = (wScreen - w)/2.0;
      }
    } else {
      if (index == LIVEVIEW_ANAGLYPH) {  // check for 2D anaglyph image
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
    if (mirror && index == LIVEVIEW) {
      pushMatrix();
      scale(-1, 1);
      image(img, -screenWidth+hOffset, (screenHeight-h)/2.0, w, h);
      popMatrix();
    } else {
      if (mirror && index == LIVEVIEW_ANAGLYPH) {
        pushMatrix();
        scale(-1, 1);
        if (screenWidth < screenHeight) {
          image(img, -screenWidth+hOffset, (screenHeight-h)/2.0, w, h);
        } else {
          image(img, -screenWidth+hOffset, (screenHeight-h), w, h);
        }
        popMatrix();
      } else {
        if (zoomPhoto) {
          if (zoomPhotoIndex == 0) {  // left eye image
            image(img, 0, -(screenHeight-h)/2.0, 2*w, 2*h);
            text("Left", 20, height/2);
          } else {  // right eye image
            image(img, horizontalOffset-w, -verticalOffset-(screenHeight-h)/2.0, 2*w, 2*h);
            text("Right", 20, height/2);
          }
        } else {
          image(img, hOffset, (screenHeight-h)/2.0, w, h);
        }
      }
    }
    if (DEBUG_ONSCREEN) {
      fill(255);
      text("draw3DImage image "+" w=" + wImg+ " h="+hImg+" arImg="+arImg, 20, height/2-40);
      text("draw3DImage "+" w=" + w+ " h="+h+" index="+index, 20, height/2);
      text("draw3DImage "+ " anaglyph="+anaglyph+ " mirror="+mirror, 20, height/2+40);
    }
  }

  private void draw3DreviewImage(PImage img, int index) {
    if (img == null) return;
    if (index == REVIEW) {
      setDisplayImage(img, index);
    }
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

  private void drawReviewImage(PImage img, int index) {
    float hImg= img.height;
    float wImg = img.width;
    float arImg = wImg/hImg;  // aspect ratio of image
    float hScreen = (float) screenHeight;
    float wScreen = (float) screenWidth;
    float h = 0;
    float w = 0;
    float hOffset = 0;

    h = hScreen ;
    w = hScreen * arImg;
    hOffset = (wScreen - w)/2.0;

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
      if (anaglyph)
        draw3DreviewImage(images[REVIEW_ANAGLYPH], REVIEW_ANAGLYPH);
      else
        draw3DreviewImage(images[currentState], REVIEW);
    } else {
      if (DEBUG) println("currentState="+currentState);
      drawReviewImage(images[currentState], currentState);
    }
  }

  public void drawLast() {
    if (numberOfPanels == 1) {
      if (images[SBS] != null) {  // check that images have been saved for review
        if (camera3D) {
          draw3DreviewImage(images[review], review);
        } else {
          drawReviewImage(images[REVIEW], REVIEW);
        }
      } else {
        fill(255);
        drawScreenText("NO IMAGES", 0, screenHeight);
        //text("NO IMAGES", screenWidth/4, screenHeight);
      }
    } else { // collage not tested for 3D mode TODO
      if (collage[review] != null) {
        drawReviewImage(collage[review], review);
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
    currentImage = imageProcessor.processImage(input);
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
    if (DEBUG) println("Start photo shoot countdown -----------------------------");
    isPhotoShoot = true;
    countdownDigit = start+1;
    if (noCountDown) {
      noCountDown = false;
      countdownDigit = 1; // smile only before shutter
    }

    countdownTimer = new Timer();
    // define a task to decrement the countdown digit every second
    TimerTask task = new TimerTask() {
      public void run() {
        countdownDigit--;
        if (countdownDigit < 0) {
          // stop the timer when the countdown reaches 0
          countdownTimer.cancel();
        }
      }
    };
    // start the timer
    countdownTimer.scheduleAtFixedRate(task, 0, 1000);
  }

  public void endPhotoShoot() {
    endPhotoShoot = true;
    oldShootCounter = 0;
    if (DEBUG) println("endPhotoShoot ******************");
  }

  // draw photo shoot count down digits
  public void drawCountdownSequence() {
    background(0);
    int digit = getCountDownDigit();
    if (digit > 0 && !endPhotoShoot) {
      drawCurrent();
      fill(0x80FFFF80);
      textSize(largeFontSize);
      String digitText = str(digit);
      float tw = textWidth(digitText);
      int th = largeFontSize/2;
      if (orientation == LANDSCAPE) {
        drawScreenText(digitText, 0, screenHeight/2 + th);
      } else {
        pushMatrix();
        translate(screenWidth/2+th, screenHeight/2);
        rotate(-HALF_PI);
        text(digitText, -tw/2, 0);
        popMatrix();
      }
      textSize(fontSize);
      fill(255);
    } else if (digit == 0) {
      drawCurrent();
      fill(0x80FFFF80);
      textSize(largeFontSize);
      String digitText = finalCountdownText;
      float tw = textWidth(digitText);
      int th = largeFontSize/2;
      if (orientation == LANDSCAPE) {
        drawScreenText(digitText, 0, screenHeight/2 + th);
      } else {
        pushMatrix();
        translate(screenWidth/2+th, screenHeight/2);
        rotate(-HALF_PI);
        text(digitText, -tw/2, 0);
        popMatrix();
      }
      focusPush();  // trigger Focus
      textSize(fontSize);
      fill(255);
    } else if (digit == -1) {
      // flash screen and take photo
      //background(0);
      takePhoto(doubleTrigger, false);  // take photo
      boolean done = incrementState();
      if (done) {
        if (DEBUG) println("Done currentState = "+currentState +
          " numberOfPanels="+numberOfPanels+" isPhotoShoot="+isPhotoShoot);
        drawPrevious();
        // show Saved message with date and time
        String savedText = "Saved "+datetime;
        float tw = textWidth(savedText);
        if (orientation == LANDSCAPE) {
          drawScreenText(savedText, 0, screenHeight/24);
        } else {  // TODO 3D for portrait orientation twin cameras
          float angleText = radians(270);
          pushMatrix();
          //translate(screenWidth/2, screenHeight/2);
          translate(screenWidth/32, screenHeight/2+tw/2);
          rotate(angleText);
          text(savedText, 0, 0);
          popMatrix();
        }
      } else {
        if (DEBUG) println("currentState = "+currentState + " numberOfPanels="+numberOfPanels);
        if (DEBUG) println("isPhotoShoot="+isPhotoShoot);
        isPhotoShoot = false;
        tryPhotoShoot();
      }
    }
  }

  // not tested for 3D anaglyph
  void drawCollage(PImage img) {
    if (img != null) {
      background(0);
      //float bw = (screenWidth-(screenHeight/printAspectRatio))/2.0;
      //int sx = int(bw);
      //image(collage2x2, sx/2, 0, collage2x2.width/4, collage2x2.height/4);
      //image(img, sx, 0, img.width/(2*cameraHeight/screenHeight), img.height/(2*cameraHeight/screenHeight));
      image(img, img.height*screenAspectRatio, screenHeight);
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
        saveRawImage(currentRawImage, currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime, rawFileType);
      } else {
        saveRawImage(currentRawImage, currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime, rawFileType);
      }
    }
    if (camera3D) {
      if (DEBUG) println("save filter "+ imageProcessor.filterNum + " or offset photo "+ (currentState+1) + " " + datetime);
      if (anaglyph) {
        save3DImage(currentRawImage, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
      } else {
        //andy check save3DImage(currentImage, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
        save3DImage(currentRawImage, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
      }
    } else {
      if (DEBUG) println("save 2D photo "+ (currentState+1) + " " + datetime);
      saveImage(images[currentState], currentState, OUTPUT_FOLDER_PATH, OUTPUT_FILENAME, datetime + "", fileType);
    }
    currentState += 1;
    if (currentState >= numberOfPanels) {
      if (numberOfPanels == 4) {
        if (DEBUG) println("save collage2x2 " + datetime);
        PGraphics pg = saveCollage(collage, OUTPUT_FOLDER_PATH, OUTPUT_COMPOSITE_FILENAME, datetime, fileType);
        collage[4] = pg.copy();
        pg.dispose();
        currentState = 0;
        images[currentState] = collage[4];
      } else {
        currentState=0;
        drawPrevious();
      }
      done = true;
      endPhotoShoot();
    }
    return done;
  }

  // Save images from 2D cameras
  public void saveImage(PImage img, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    if (img == null) return;
    // crop and save
    collage[index] = cropForPrint(img, printAspectRatio);  // adjusts for mirror
    filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_cr"+ "." + filetype;
    collage[index].save(filename);
    images[index] = collage[index];
    if (orientation == PORTRAIT) {
      setEXIF(filename);
    }
  }

  // save images from 3D cameras
  public void saveRawImage(PImage img, int index, String outputFolderPath, String outputFilename, String suffix, String filetype) {
    String filename;
    // crop and save
    filename = outputFolderPath + File.separator + outputFilename + suffix +"_"+ number(index+1) + "_Raw" + "." + filetype;
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
    if (DEBUG) println("headerText width="+hw+" "+headerText);
    pg.text(headerText, hw+printParallax, fontSize );
    pg.text(headerText, dx + hw, fontSize );

    // footer
    pg.fill(0);  // black text
    pg.textSize(fontSize);
    println("eventInfoText="+eventInfoText);
    String footerText = eventInfoText;
    float fw = round(((printPxWidth/2)-pg.textWidth(footerText))/2.0);
    if (DEBUG) println("footerText width="+fw + " "+footerText);
    pg.text(footerText, fw+printParallax, dh + dd + fontSize );
    pg.text(footerText, dx + fw, dh + dd + fontSize );
    pg.endDraw();

    img = pg.copy();
    return img;
  }

  // crop for printing 2D photo or 2D collage using print paper aspect ratio
  PImage cropForPrint(PImage src, float printAspectRatio) {
    if (DEBUG) println("cropForPrint "+printAspectRatio+ " mirrorPrint="+mirrorPrint+" " +(orientation==LANDSCAPE? "Landscape":"Portrait"));
    float imgAR = (float) src.width / (float) src.height;
    if (DEBUG) println("imgAR="+imgAR);
    // crop creating a new PImage
    //float bw = (printPxWidth); // pixel width for printer at 300 dpi
    float bw = (cameraWidth-(cameraHeight*printAspectRatio))/2.0;
    if (DEBUG) println(">>>bw="+bw);
    int iw = int(bw);
    int sx = iw;
    int sy = 0;
    int sw = cameraWidth-int(2*bw);
    int sh = cameraHeight;
    int dx = 0;
    int dy = 0;
    int dw = sw;
    int dh = cameraHeight;
    int dd = dw;

    if (imgAR < printAspectRatio) {
      bw = (src.height*printAspectRatio)-src.width;
      if (DEBUG) println("<<<bw="+bw);
      sx = 0;
      sy = 0;
      sw = src.width;
      sh = src.height;
      dx = int(bw/2.0);
      dy = 0;
      dd = src.width;
      dw = int(bw+src.width);
      dh = src.height;
    }

    PImage img = createImage(dw, dh, RGB);
    img.copy(src, sx, sy, sw, sh, dx, dy, dd, dh);  // cropped copy
    // next mirror image if needed
    if (mirrorPrint && orientation == PORTRAIT) {
      PGraphics pg;
      pg = createGraphics(dw, dh);
      pg.beginDraw();
      pg.background(255);
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
      pg.background(255);
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
      pg.background(255);
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
    if (format != MONO) return;

    float x = 0;
    float y = 0;
    float w = (screenWidth-(screenHeight*printAspectRatio))/2.0;
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
