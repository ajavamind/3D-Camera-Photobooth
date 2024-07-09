// Screen Display sketch //<>//
// Photo booth uses a second display screen to show half width SBS PImages on a 3D monitor or tablet

Display auxMonitor;

void createAuxDisplay(String name) {
  if (auxDisplay.status) {
    auxMonitor = new Display("Display2", auxDisplay);
    String[] args = {this.toString() }; // for attaching name stripped by new sketch
    String[] newArgs = {name };
    PApplet.runSketch(concat(args, newArgs), auxMonitor);
  }
}

void setAuxDisplayImage(PImage img, int index) {
  if (auxMonitor == null) return;
  if (auxDisplay.status) {  // assumes 3DHW
    if (index == LIVEVIEW)
      auxMonitor.setImage(img, horizontalOffset, verticalOffset);
    else
      auxMonitor.setImage(img, 0, 0);  // already adjusted
  }
}

// convert screen image to half width
// only for main display
void convertScreen() {
  if (mainDisplay.format.equals("3DHW")) {
    hwsbs = get();
    background(0);
    copy(hwsbs, 0, 0, width/2, height, width/8, 0, width/4, height);
    copy(hwsbs, width/2, 0, width/2, height, width/2+width/8, 0, width/4, height);
  }
}

/**
 * Class for all Auxilary monitors. 
 * Each auxilary monitor requires a Display sketch
 */
class Display extends PApplet {
  String name;
  Monitor monitor;
  PImage monitorImage;
  PImage sbsImage;

  // constructor
  Display(String name, Monitor monitor) {
    this.name =  name;
    this.monitor = monitor;
  }

  void setImage(PImage img, int horzAdj, int vertAdj) {
    //if (DEBUG) println("horzAdj="+horzAdj + " vertAdj="+vertAdj +" img w="+img.width+ " h="+img.height);
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
    fullScreen(RENDERER, monitor.id);
  }

  void setup() {
    if (DEBUG) println(name + " setup()");
    fill(192);
    textSize(96);
    String message = name + " Not Ready";
    text(message, width/2 - (textWidth(message)/2), height/2);
  }

  void draw() {
    background(0);
    if (monitorImage != null) {
      if (sbsImage != null && sbsImage.width > 0) {
        image(sbsImage, (width-(sbsImage.width & 0xFFFE))/2, 0, sbsImage.width, sbsImage.height);
      }
    } else {
      String message = name + "3D Display";
      text(message, width/2- (textWidth(message)/2), height/2);
    }
    noLoop();  // prevent another draw until a new image arrives in setImage
  }

  void keyPressed() {
    if (DEBUGKEY) println(name + " key="+key + " keydecimal=" + int(key) + " keyCode="+keyCode);
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
