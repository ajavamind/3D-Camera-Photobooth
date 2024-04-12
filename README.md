# 3D Camera Photo Booth
**This is my open source documentation for a 3D Camera Photo Booth demonstration project to be presented at the 2024 Maker Faire Philadelphia.**

This repository contains open source code for my 3D camera photo booth [Processing](https://www.processing.org) Java sketch application that operates one 3D webcam and optionally multiple additional 2D/3D cameras. 

This application works within a web interface framework defined in the project Photobooth on Github [https://github.com/PhotoboothProject/photobooth](https://github.com/PhotoboothProject/photobooth). The web interface framework is not a requirement of this project, but is certainly very useful for showing a gallery of images taken with a photo booth camera at a public event.

## Introduction

The 3D Camera Photo Booth sketch application, written in Processing Java, takes 3D photos of subjects after a countdown sequence. 
I wrote my photo booth camera controller using Processing so that I could experiment with various cameras and image filters.
My design was influenced by another photo booth project on Github [https://github.com/arkitex/processingPhotobooth](https://github.com/arkitex/processingPhotobooth).

My code is a complete rewrite with some similar structural elements. I also wrote a 2D photo booth controller that was forked from arkitex. See this link: [https://github.com/ajavamind/processingPhotobooth](https://github.com/ajavamind/processingPhotobooth). I used my 2D version of processingPhotobooth for a few family celebrations. The photo booth worked out well and everyone enjoyed the experience and photos.

The photo booth application uses a synchronized twin lens 3D camera USB webcam to live view and capture photos from a video stream.
The photo booth displays captured images in either side-by-side (SBS) left and right eye view format or red-cyan Anaglyph stereo format.
To see the images in stereo requires a stereoscope or 3D anaglyph red/cyan glasses. 
The images can be downloaded to view with a glasses free 3D tablet.
There is also a capability to print the SBS and Anaglyph images using a Canon SELPHY CP1300 printer.

My photo booth application runs on a Windows 10/11 mini PC attached to a 1920x1080 monitor matching the 3D USB webcam single eye resolution. 
Processing sketches can run on other systems like Apple IOS, Linux, Raspberry Pi, Android devices, and Web Browsers (with Processing P5.js). I only implemented this photo booth application for Windows version using Java. A lot of my code experience is with Java so it was my first choice for implementation. When porting a Java sketch to other systems there may be problems with using supporting libraries. Anyway there is not enough time to explore implementation on additional platforms.

A portable WiFi router establishes a small private local area WiFi network for the photo booth. The router is normally not connected to the Internet. The mini PC connects to the local network for photo transfers to other connected devices such as a notebook computer, Chromebook, mobile phones, 3D tablets. The local network also transmits broadcast messages to multiple cameras capable of receiving focus/shutter triggers using a custom camera app or an Arduino WiFi device attached to one or more cameras.

Because 3D camera lenses may not be perfectly aligned the app can adjust the left and right images from the camera vertically during setup.
The app can also adjust the photo stereo window using a horizontal parallax value to compensate for the interaxial distance between the camera lens and the subject distance from the camera.
Before capture a subject will see a live view mirror image of themselves on a monitor in either SBS or Anaglyph format.

A wireless buzzer box uses three contact switches for controlling the photo booth by the subject audience. 

A separate keyboard and mouse attached to the mini PC gives the photo booth operator key commands to control the operation of the photo booth during setup and debug.

Captured photos are saved into a folder accessed by an Apache web server program running in the background on the mini PC.
This allows a connected web browser devices to show thumbnails of all gallery photos captured in a session. 
A browser can download a photo for printing on a Canon SELPHY CP1300 4x6 inch printer.

## 3D Photo Booth Project Hardware

This section describes the hardware components of the photo booth for public operation:

### Dedicated Mini PC
I use a Beelink SER model Mini PC [www.bee-link.com](www.bee-link.com) with AMD Ryzen 7 4700U, Radeon Graphics 2 GHz, 512 GB SSD, 16 GB RAM. Windows 11 Pro with attached wired keyboard and wired mouse. Sometimes I use a mini Bluetooth wireless keyboard with touchpad for mouse input instead of the wired devices.

I set Windows to best performance power mode, set screen never sleeps option, screen saver after 10 minutes without keyboard or mouse input.
It may be connected to the Internet with a CAT5 cable, but I normally do not connect the photo booth to the Internet except for code development.

### Computer Monitor 1920x1080
I am using a LG Full HD 1080P monitor and attach the mini PC to its back. The monitor is 60 Hz with an IPS display that is good for showing photos. The monitor resolution matches the one eye view of the 3D camera. A better option might be a portable monitor with a stand, but the desktop monitor was already available. My monitor has speakers, but is not touch screen. I can see this application using a glasses free computer monitor/TV, but is too expensive for me at this time. 

### WiFi Portable Router
I use TP-Link AC750 Wi-Fi Travel Router
to establish a local area network for the photo booth.
It can be connected to the Internet with a CAT5 cable.

### Printer
Canon SELPHY Printer CP1300 for 4x6 prints, connected to local WiFi network.

### Buzzer Box
The Buzzer box is a repurposed Bluetooth wireless mouse. The box has 3 contact switches. The switches connect to buttons in the wireless mouse.

1) LEFT button: Start the countdown capture sequence to take a photo
2) MIDDLE button: Toggle between live view and review of last captured photo in both SBS and Anaglyph display modes.
3) RIGHT button: Toggle between Side-by-side or Anaglyph live view display of the subject. The Anaglyph view needs red-cyan glasses for viewing stereoscopically. This mode is very helpful for giving the subject a reference about where to position themselves in relation to the stereo window.

### Ring light
The 3D webcam works best with off camera lighting. The ring light contains a camera support or as a separate light with the camera on a tripod.

### 3D Cameras
3D webcams used:  
  - [QooCam EGO 3D camera](https://www.kandaovr.com/qoocam-ego) dual lens 1080P in USB webcam mode. This camera gives the best image in this group.
  - [ELP USB 1080P 3D Dual Lens](https://www.elpcctv.com/elp-4mp-3840x1080p-60fps-synchronous-dual-lens-usb-camera-module-with-no-distortion-85-degree-lens-p-406.html) synchronized webcam 
  - [ELP USB 960P 3D Dual Lens](https://www.elpcctv.com/13mp-960p-usb20-dual-lens-usb-camera-module-synchronization-camera-for-3d-depth-detection-p-126.html) synchronized webcam

### Notebooks, Chromebooks, Tablets
These devices can be used with a Web browser to view the saved photo gallery and set up and modify the server parameters including 2D or 3D mobile phone/tablets.

## Processing IDE

I currently build the 3D photo booth application for Windows 11 OS with Processing IDE version 4.3 in Java mode.
Additional processing libraries required are:
- Video Library for Processing 4
- Sound (Processing Foundation)
- oscP5 (Contributed library) for remote camera WiFi triggering

## Software Tools Needed For Photo Booth Operation

The application requires additional software tools to build a complete photo booth. These components are:

### Photobooth web interface
My 3D photo booth application works within the web interface framework defined at [https://github.com/PhotoboothProject/photobooth](https://github.com/PhotoboothProject/photobooth)
I am using version 3, but version 4 is available (I have not tried version 4). I followed the instructions for windows setup that defaulted to installing the Apache server. I did not use the digiCamControl camera controller [https://digicamcontrol.com/](https://digicamcontrol.com/) because my application replaces this camera controller. I customized this interface to view the saved photo gallery, download and print photos, and operate a slide show. I can downloaded SBS photos to a 3D glasses free tablet, the Leia Inc Lumepad, and view in 3D without glasses by opening the photo in the LeiaPlayer app.

### Apache Web Server
An Apache web server runs in background on the Windows PC. It provides a gallery listing of photos taken and administrative setup of the Photobooth server features. To access the server on a local network requires turning off Windows network security in settings. This is why the portable router is not connected to the Internet.

### Exiftool
exiftool.exe sets photo orientation in JPG exif information area when needed. Calls to exiftool are made from command line execution invoked from the application.
ExifTool can be downloaded from [https://exiftool.org/](https://exiftool.org/)
See [https://github.com/exiftool/exiftool](https://github.com/exiftool/exiftool) for additional information.

### IrfanView Graphic Viewer
The photo booth application uses IrfanView for printing photos. IrfanView has a feature to save printer profiles to match the printer. I found Windows print functions could not set printer profiles so it was not adequate for printing 3D side-by-side photos.
[https://www.irfanview.com/](https://www.irfanview.com/)

Calls to "i_view64.exe" are used in the Printer command section of the Photobooth web interface.

## Advanced Features

### Image Processing
Images from the input webcam can be seen in live view filtered with the ImageProcessor. The following filters are implemented:
1. Grayscale: Converts to a grayscale monochrome photo.
2. Positive: Threshold converter to two color black and white images
3. Negative: Inverse Threshold converter to two color white and black images
4. Posterize: Posterization using different built-in level settings.

### Multiple Cameras
In addition to a wired USB 3D Camera, the photo booth capture sequence can trigger multiple 2D and 3D cameras that are connected to the photo booth local WiFi network. 
The photo booth application sends control focus and shutter broadcast commands to multiple Android phone cameras on the network almost simultaneously, 
that run the Multi Remote Camera app. This open source camera app is available on SourceForge.net at

 [https://sourceforge.net/projects/multi-remote-camera/](https://sourceforge.net/projects/multi-remote-camera/)
 The MRC app is a modified version I made from [Open Camera](https://sourceforge.net/projects/opencamera/) app on SourceForge.net 
 
The camera phone running Multi Remote Camera app should have WiFi enabled and be connected to the same network as the photo booth app.
I use older second hand Android phones to install MRC.
You may need put the phone in developer mode to install this app. 
MRC may not use all the camera features available in the phone.

To view photos taken with MultiRemoteCamera app, change its settings for WiFi Remote Control and optional HTTP Server turned on. 
In the Multi Remote Camera App: 
 1) turn on the WiFi Remote Control using Settings->Camera Controls -> WiFi Remote Control. 
 2) turn on the HTTP Server using Settings->Camera Controls -> HTTP Server. 
 
On the phone the same folder used to store pictures is the folder used by the built-in web server. 
A web browser can see a directory listing with the link http://PHONE_IP_ADDRESS:8080 - change PHONE_IP_ADDRESS to match your phone. 
The app will show the PHONE_IP_ADDRESS by selecting Settings -> Camera Controls -> Pairing QR Code. 
You can use the QR code to launch a browser on a computer or phone connected to the same network.Special camera software for Android  devices operate phone cameras. The trigger is nearly simultaneous when the cameras are prefocused on the subject. Up to 250 cameras can be connected.

A separate camera focus/shutter control box I built uses an ESP8266 microcontroller with a wired connections to a twin camera 3D rig.
See description of hardware and software at [https://github.com/ajavamind/Remote-Camera-Receiver](https://github.com/ajavamind/Remote-Camera-Receiver)

## 3D Photo Booth Software
... description to be added


## Notes
1. The myIPaddress.bat Windows batch file is a helper function to lookup the computer IP address running the photobooth application.

## Feature Enhancements 

I may add some of these new features when time permits:

1. Image Processor filter for green screen for background replacement
2. Camera click and Buzzer button sound generation
3. Crop images for 8x9 aspect ratio. This aspect ratio will give a larger image when printing 4x6 cards for stereoscope viewing.
4. Use twin 2D web cameras instead of a 3D camera. Camera left and right image synchronization will not be as good as a 3D camera.
5. Incorporate OpenCV image processing filters.
6. Video storage
7. Anaglyph only mode for capturing four photos into a collage during a countdown sequence


   

