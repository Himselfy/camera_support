import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class Camera {
  static const MethodChannel _channel =
      const MethodChannel('com.flutter.plugins.camera');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> initialize() async {
    final int textureId = await _channel.invokeMethod('initialize');
    return textureId;
  }

  static Future<void> takePicture(String filePath) async {
    await _channel.invokeMethod('takePicture', <String, dynamic>{'filePath': filePath });
  }

  static Future<void> setFlashMode(FlashMode mode) async {
    await _channel.invokeMethod("setFlashMode", <String, dynamic>{"mode": mode.index } );
  }

 static Future<FlashMode> getFlashMode() async {
    var result = await _channel.invokeMethod("getFlashMode");
    return FlashMode.values[result];
  }

  static Future<AspectRatioType> getAspectRatio() async{
   dynamic result = await _channel.invokeMethod("getAspectRatio"); 
   return new AspectRatioType(result["x"],result["y"]);
  }

  static Future<void> dispose(int textureId) async{
    await _channel.invokeMethod(
        'dispose',
        <String, dynamic>{'textureId': textureId},
      );
  }

  static Future<void> setAspectRatio(AspectRatioType ratio) async {
    await _channel.invokeMethod("setAspectRatio", <String, dynamic>{"x": ratio.x, "y": ratio.y } );
  }

  static Future<List<AspectRatioType>> getSupportedAspectRatios() async{
    List result = await _channel.invokeMethod("getSupportedAspectRatios"); 
    //var convertedResult = result as List<Map<String,int>>;   
    List<AspectRatioType> resultList = new List<AspectRatioType>();
    for(var i=0;i< result.length;i++){
      var ratio = new AspectRatioType(result[i]["x"],result[i]["y"]);
      resultList.add(ratio);
    }
    return resultList;
  }
  

}


class CameraPreview extends StatefulWidget {
  final CameraController cameraController;
  CameraPreview(this.cameraController);

  @override
  State<StatefulWidget> createState() => new CameraPreviewState(cameraController);

}

class CameraPreviewState extends State<CameraPreview>{
  CameraController cameraController;
  
  CameraPreviewState(this.cameraController){
    this.cameraController.onAspectRatioChange = this.onAspectRatioChanged;
  }

  @override
  Widget build(BuildContext context) {
    return cameraController.isInitialized ? renderPreview() : renderNotInitializedNotification();
  }

  @override
  void dispose() {
    super.dispose();
    cameraController.dispose();
  }

  Widget renderPreview(){   
    return new Texture(textureId: cameraController.textureId); 
  }

  Widget renderNotInitializedNotification(){
    return  new Container(child: new Text("Not initialized"), color: Colors.green,);
  }

  void onAspectRatioChanged(AspectRatioType ratio){
    this.setState(()=> {});
  }

}

class CameraController   {
   ValueChanged<AspectRatioType> onAspectRatioChange;

   int textureId;
   bool isInitialized = false;
   bool isDisposing = false;
   AspectRatioType currentAspectRatio;



   Future<bool> initialize() async{
      textureId = await Camera.initialize();
      isInitialized = true;         
      currentAspectRatio = await getAspectRatio();   
      return isInitialized;
   }

   Future<void> takePicture(String filePath) async{
     await Camera.takePicture(filePath);
   }

  Future<void> setFlashMode(FlashMode mode) async {
    return await Camera.setFlashMode(mode);
  }

   Future<FlashMode> getFlashMode() async {
    return await Camera.getFlashMode();
  }

   Future<AspectRatioType> getAspectRatio() async{
     return await Camera.getAspectRatio();
  }

   Future<void> setAspectRatio(AspectRatioType ratio) async {
    currentAspectRatio = ratio;
    onAspectRatioChange(currentAspectRatio);
    return await Camera.setAspectRatio(ratio);
  }

   Future<List<AspectRatioType>> getSupportedAspectRatios() async{
    return Camera.getSupportedAspectRatios();
  }   

  Future<void> dispose() async {
    if(!isDisposing){
      isDisposing = true;
      await Camera.dispose(this.textureId);      
    }
  }
}

enum FlashMode {
  OFF, 
  ON,
  TORCH, 
  AUTO 
}

class AspectRatioType {
  AspectRatioType(this.x,this.y);
  int x;
  int y;
}