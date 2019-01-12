import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:camera_support/camera_support.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  CameraController cameraController;

  _MyAppState(){
    cameraController = new CameraController();
  }

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initCamera();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Camera.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> initCamera() async {
    await cameraController.initialize();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Plugin example app Running on: $_platformVersion\n'),
        ),
        body: new Center(
          child: CameraPreview(cameraController)
        ),
        floatingActionButton: new Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            new FloatingActionButton(heroTag: "changeAspectRatio", onPressed: ()=> this.changeAspectRatio(), child: new Icon(Icons.aspect_ratio)),
            new FloatingActionButton(heroTag: "changeFlashMode", onPressed: ()=> this.changeFlashMode(), child: new Icon(Icons.flash_auto)),
            new FloatingActionButton(heroTag: "takePic", onPressed: ()=> this.takePicture(), child: new Icon(Icons.camera)),
          ],
        ) 
      ),
    );
  }

  Future changeAspectRatio() async {
    var supportedAspectRatios = await cameraController.getSupportedAspectRatios();
    var currentRatio = await cameraController.getAspectRatio();
    currentAspectRatioIndex = supportedAspectRatios.indexWhere( (ar)=> ar.x == currentRatio.x && ar.y == currentRatio.y );
    var nextAspectRatioIndex = currentAspectRatioIndex + 1;
    if(nextAspectRatioIndex >= supportedAspectRatios.length) nextAspectRatioIndex = 0;

    cameraController.setAspectRatio(supportedAspectRatios[nextAspectRatioIndex]);
    currentAspectRatioIndex = nextAspectRatioIndex;

  }
  int currentAspectRatioIndex;

  Future changeFlashMode() async {
    cameraController.setFlashMode(FlashMode.OFF);
  }

  Future takePicture()async {
    var timeStamp = new DateTime.now().millisecondsSinceEpoch.toString();
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Camera_Example';
    await new Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timeStamp}.jpg';
    cameraController.takePicture(filePath);
    var file = new File(filePath);
    List<int> fileData;
    while(true){
      if(await file.exists()){
        print("File created");
        fileData = file.readAsBytesSync();
        if(fileData.length > 0) break; 
      } else print("Waiting for file to be created");
    }
    print("File size: " + fileData.length.toString());

  }
}
