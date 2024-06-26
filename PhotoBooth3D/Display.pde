// Screen Display sketch
// Photo booth uses a second display screen to show half width SBS PImages on a 3D monitor or tablet

Display displayMonitor;

void createDisplay(String name) {
  String[] args = {this.toString() }; // for attaching name stripped by new sketch
  String[] newArgs = {name };
  displayMonitor = new Display();
  PApplet.runSketch(concat(args, newArgs), displayMonitor);
}

void setDisplayImage(PImage img, int index) {
  if (index == LIVEVIEW)
    displayMonitor.setImage(img, horizontalOffset, verticalOffset);
  else
    displayMonitor.setImage(img, 0, 0);  // already adjusted
}

class Display extends PApplet {
  PImage monitorImage;
  PImage sbsImage;

  void setImage(PImage img, int horzAdj, int vertAdj) {
    if (DEBUG) println("horzAdj="+horzAdj + " vertAdj="+vertAdj +" img w="+img.width+ " h="+img.height);
    monitorImage = imageProcessor.alignSBS(img, horzAdj, vertAdj, false);

    //convert full SBS to half width SBS for 3D Monitor/TV/Tablet
    sbsImage = createImage(monitorImage.width/2, monitorImage.height, RGB);  // default black background

    // copy left side
    sbsImage.copy(monitorImage, 0, 0, monitorImage.width/2, monitorImage.height,
    /*destination*/      0, 0, sbsImage.width/2, sbsImage.height);

    // copy right side
    sbsImage.copy(monitorImage, monitorImage.width/2, 0, monitorImage.width/2, monitorImage.height,
    /*destination*/      sbsImage.width/2, 0, sbsImage.width/2, sbsImage.height);

    //if (DEBUG) println("Display monitorImage w="+monitorImage.width + " h="+monitorImage.height+
    //" sbsImage w="+sbsImage.width+" h="+sbsImage.height);

    loop();  // to update screen monitor
  }

  void settings() {
    fullScreen(RENDERER, displayId[AUX_DISPLAY]);
  }

  void setup() {
    if (DEBUG) println("Display setup()");
    fill(192);
    textSize(96);
    String message = "3D Display";
    text(message, width/2- (textWidth(message)/2), height/2);
  }

  void draw() {
    background(0);
    if (monitorImage != null) {
      if (sbsImage != null && sbsImage.width > 0) {
        image(sbsImage, (width-(sbsImage.width & 0xFFFE))/2, 0, sbsImage.width, sbsImage.height);
      }
    } else {
      String message = "3D Display";
      text(message, width/2- (textWidth(message)/2), height/2);
    }
    noLoop();  // prevent another draw until a new image arrives in setImage
  }

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
    // save for main loop in PhotoBooth3D sketch
    // we do not do any other work in this callback thread!
    lastKey = key;
    lastKeyCode = keyCode;
  }
}
