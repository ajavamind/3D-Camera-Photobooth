// Apply filters to the live view
// Processing filters available are:
String[] filters = {"NONE", "THRESHOLD", "GRAY", "OPAQUE", "INVERT", "POSTERIZE", "BLUR", "ERODE", "DILATE"};

class ImageProcessor {
  int filterNum = 0; // image filter index

  public ImageProcessor() {
    filterNum = 0;
    colorMode(RGB, 255, 255, 255, 100);
  }

  public PImage processImage(PImage temp) {
    switch (filterNum) {
    case 0:
      temp.filter(0);
      break;
    case 1:
      temp.filter(GRAY);
      break;
    case 2:
      temp.filter(THRESHOLD, 0.5);  // Positive
      break;
    case 3:
      temp.filter(INVERT);
      temp.filter(THRESHOLD, 0.5);  // Negative
      break;
    case 4:
      temp.filter(POSTERIZE, 13);
      break;
    case 5:
      temp.filter(POSTERIZE, 8);  // best
      break;
    case 6:
      temp.filter(POSTERIZE, 5);
      break;
    case 7:
      temp.filter(POSTERIZE, 4);
      break;
    case 8:
      temp.filter(POSTERIZE, 3);
      break;
    case 9:
      temp.filter(POSTERIZE, 2); // TODO green screen etc.
      break;
    default:
      if (DEBUG) println("Internal Error filterNum="+ filterNum + " out of range 0 to 9");
      temp.filter(0);
      break;
    }
    if (anaglyph) {
      temp = alignAnaglyph(temp, horizontalOffset, -verticalOffset, mirror);
    }
    return temp;
  }

  // mirror 3D image
  // swaps left and right image as side affect
  PImage mirror3D(PImage src) {
    PImage img;
    int dw = src.width;
    int dh = src.height;

    PGraphics pg;
    pg = createGraphics(dw, dh);
    pg.beginDraw();
    pg.background(0);
    pg.pushMatrix();
    pg.scale(-1, 1);
    pg.image(src, -dw, 0, dw, dh);  // horizontal flip
    pg.popMatrix();
    pg.endDraw();
    img = pg.copy();
    pg.dispose();
    return img;
  }

  public PImage createWindowPane() {
    PImage temp = createImage(screenWidth, screenHeight, ARGB);
    temp.loadPixels();
    for (int i=0; i<temp.width*temp.height; i++) {
      temp.pixels[i] = 0x80FFFF80;
    }
    temp.updatePixels();
    return temp;
  }

  /**
   * Create anaglyph using side-by-side LR
   * PImage img Input image with left and right SBS eye views
   * horzOffset camera alignment horizontally to adjust stereo window placement
   * vertOffset adjust camera misalignment vertically for stereo
   * boolean mirror Swap image left and right eye pixel sources
   */
  public PImage alignAnaglyph(PImage img, int horzOffset, int vertOffset, boolean mirror) {
    int vert = vertOffset;
    int horz = horzOffset;
    int w2 = img.width;
    int w = img.width/2;
    int h = img.height;
    PImage temp = createImage(w, h, RGB);
    img.loadPixels();
    temp.loadPixels();
    int cr = 0;  // pixel color right eye cyan (green+blue) channels
    int cl = 0;  // pixel color left eye red channel
    int idx = 0; // computed index into pixel array of image
    for (int j=0; j<h; j++) {  // j vertical scan rows
      for (int i=0; i<w; i++) { // i horizontal scan columns
        cr = img.pixels[j*w2 + i+w]; // get pixel color from right eye row,col
        idx = (j+vert)*w2 + i+horz;  // adjust index for horzizonal and vertical offsets
        if ( (j+vert) >= 0 && (j+vert) < h && (i+horz) >= 0 && ((i+horz) < w) ) {
          cl = img.pixels[idx]; // in bounds of array, so get pixel color
        } else {
          cl = 0; // make unused pixel transparent when adjusted
          cr = 0;
        }
        // store color in anaglyph PImage pixel array
        if (mirror) {
          temp.pixels[j*w + i] = color(red(cr), green(cl), blue(cl)); // store merged anaglyph pixel crosseye
        } else {
          temp.pixels[j*w + i] = color(red(cl), green(cr), blue(cr)); // store merged anaglyph pixel parallel
        }
      }
    }

    temp.updatePixels();
    return temp;
  }

  /**
   * Align side-by-side LR image by moving right image using offsets.
   * Fill unused area with black (0)
   * PImage img SBS image with left and right side-by-side parallel
   * output img size is reduced by horzOffset and vertOffset values
   * horzOffset camera alignment horizontally to adjust stereo window placement parallax
   * vertOffset adjust camera misalignment vertically for pleasant (no eye strain) stereoscopic viewing
   * boolean mirror Swap image left and right eye pixel sources
   */
  public PImage alignSBS(PImage img, int horzOffset, int vertOffset, boolean mirror) {
    int vert = vertOffset;
    int horz = horzOffset;
    //horz = 0; // test
    //vert = 0;
    int w2 = img.width;
    int w = img.width/2;
    int h = img.height;
    int dw = w -abs(horz);
    int dw2 = 2*dw;
    int dh = h-abs(vert);
    int topd = dw2*dh;
    int tops = w2 *h;
    PImage temp = createImage(dw2, dh, RGB);
    img.loadPixels();
    temp.loadPixels();
    int idl = 0; // computed left destination index into pixel array of image
    int idr = 0; // computed right destination index into pixel array of image
    int isl = 0; // computed left source index into pixel array of image
    int isr = 0; // computed right source index into pixel array of image
    for (int j=0; j<dh; j++) {  // j vertical scan rows
      for (int i=0; i<dw; i++) { // i horizontal scan columns
        if (mirror) {
          isl = (j)*w2 + i + horz;
          isr = (j-vert)*w2 + i + w;
        } else {
          isl = (j-vert)*w2 + i + horz;
          isr = (j)*w2 + i + w ;
        }
        idl = j*dw2 + i;  // adjust index for horzizonal and vertical offsets
        idr = j*dw2 + i + dw;  // adjust index for horzizonal and vertical offsets
        if (isl > tops || isl < 0) {
          //println(" out of bounds tops= "+i+" "+j);
        } else {
          temp.pixels[idl] = img.pixels[isl]; // when in bounds of pixel array, store color
          temp.pixels[idr] = img.pixels[isr]; // when in bounds of pixel array, store color
        }
      }
    }
    temp.updatePixels();
    return temp;
  }

  /**
   * Align LR image pairs by moving right image using offsets.
   * Fill unused area with black (0)
   * PImage img left camera/eye image
   * PImage img right camera/eye image
   * output img size is reduced by horzOffset and vertOffset values
   * horzOffset camera alignment horizontally to adjust stereo window placement parallax
   * vertOffset adjust camera misalignment vertically for stereoscopic viewing
   * boolean mirror Swap image left and right eye pixel sources
   * Assumes LR images are exact same dimensions
   */
  public PImage alignLR(PImage imgL, PImage imgR, int horzOffset, int vertOffset, boolean mirror) {
    int vert = vertOffset;
    int horz = horzOffset;
    //horz = 0; // test
    //vert = 0;
    int w2 = 2*imgL.width;
    int w = imgL.width;
    int h = imgL.height;
    int dw = w - abs(horz);
    int dw2 = 2*dw;
    int dh = h - abs(vert);
    int topd = dw2*dh;
    int tops = w2 *h;
    PImage temp = createImage(dw2, dh, RGB);
    imgL.loadPixels();
    imgR.loadPixels();
    temp.loadPixels();
    int idl = 0; // computed left destination index into pixel array of image
    int idr = 0; // computed right destination index into pixel array of image
    int isl = 0; // computed left source index into pixel array of image
    int isr = 0; // computed right source index into pixel array of image
    for (int j=0; j<dh; j++) {  // j vertical scan rows
      for (int i=0; i<dw; i++) { // i horizontal scan columns
        if (mirror) {
          isl = (j)*w + i + horz;
          isr = (j-vert)*w + i + w;
        } else {
          isl = (j-vert)*w + i + horz;
          isr = (j)*w + i + w ;
        }
        idl = j*dw2 + i;  // adjust index for horzizonal and vertical offsets
        idr = j*dw2 + i + dw;  // adjust index for horzizonal and vertical offsets
        if (isl > tops || isl < 0) {
          //println(" out of bounds tops= "+i+" "+j);
        } else {
          temp.pixels[idl] = imgL.pixels[isl]; // when in bounds of pixel array, store color
          temp.pixels[idr] = imgR.pixels[isr]; // when in bounds of pixel array, store color
        }
      }
    }
    temp.updatePixels();
    return temp;
  }

  /**
   * Create color anaglyph PImage from left and right eye view PImages
   * with horizontal offset for stereo window and vertical offset for camera alignment correction
   * This method assumes the left and right images have already been swapped when mirrored for screen live view.
   */
  private PImage colorAnaglyph(PImage bufL, PImage bufR, int horzOffset, int vertOffset) {
    // color anaglyph merge left and right images
    int horz = horzOffset;
    int vert = vertOffset;
    if (DEBUG) println("colorAnaglyph horzOffset="+horzOffset + " vertOffset="+ vertOffset);
    if (bufL == null || bufR == null) {
      if (DEBUG) println("Empty images for anaglyph");
      return null;
    }

    PImage bufA = createImage(bufL.width, bufL.height, RGB);
    bufA.loadPixels();
    bufL.loadPixels();
    bufR.loadPixels();
    int w = bufL.width;
    int h = bufL.height;
    int cr = 0;  // pixel color right eye cyan (green+blue) channels
    int cl = 0;  // pixel color left eye red channel
    int idx = 0; // computed index

    for (int j=0; j<h; j++) {  // j vertical scan
      for (int i=0; i<w; i++) { // i horizontal scan
        cr = bufR.pixels[j*w + i]; // get pixel color at right eye row,col
        idx = (j+vert)*w + i+horz;  // adjust index for horzizonal and vertical offsets
        if ( (j+vert) >= 0 && (j+vert) < h && (i+horz) >= 0 && ((i+horz) < w) ) {
          cl = bufL.pixels[idx];
        } else {
          cl = 0; // make unused pixel transparent when adjusted
          cr = 0;
        }
        bufA.pixels[j*w + i] = color(red(cl), green(cr), blue(cr)); // store merged anaglyph pixel parallel
      }
    }
    bufA.updatePixels();
    return bufA;
  }

/**
 * green screen background removal 
 * PImage img
 * color c background color to remove - green value from img
 * float thres threshold typical 0.5
 * https://stackoverflow.com/questions/62380098/does-processing-transparency-support-removing-backgrounds
 */
  public void removeBackground(PImage img, color c, float thres) {
    colorMode(ARGB);
    for (int i = 0; i < img.width; i++) {
      for (int j = 0; j < img.height; j++) {
        color cp = img.get(i, j);
        //threshold accounts for compression
        if (abs(hue(cp) - hue(c)) < thres) {
          img.set(i, j, color(0, 0, 0, 0));  // alternate set alpha to 1 color(1,0,0,0) border issue?
        }
      }
    }
  }
  
}
