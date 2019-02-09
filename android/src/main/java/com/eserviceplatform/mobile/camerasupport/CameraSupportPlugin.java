package com.eserviceplatform.mobile.camerasupport;


import android.Manifest;
import android.annotation.TargetApi;
import android.app.Activity;
import android.app.Application;
import android.graphics.SurfaceTexture;
import android.os.Build;
import android.os.Bundle;
import android.util.Size;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Dictionary;
import java.util.HashMap;
import java.util.List;
import java.util.Set;
import java.util.ArrayList;

import com.eserviceplatform.mobile.camerasupport.plugin.base.AspectRatio;
import com.eserviceplatform.mobile.camerasupport.plugin.api.v14.Camera1;
import com.eserviceplatform.mobile.camerasupport.plugin.api.v21.Camera2;
import com.eserviceplatform.mobile.camerasupport.plugin.api.v23.Camera2Api23;
import com.eserviceplatform.mobile.camerasupport.plugin.base.CameraViewImpl;
import com.eserviceplatform.mobile.camerasupport.plugin.base.Constants;
import com.eserviceplatform.mobile.camerasupport.plugin.base.PreviewImpl;
import com.eserviceplatform.mobile.camerasupport.plugin.view.FlutterSurfaceView;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.view.FlutterView;

/** CameraPlugin */
public class CameraSupportPlugin implements MethodCallHandler, CameraViewImpl.Callback {
  CameraViewImpl cameraHandler;
  FlutterView flutterView;
  Activity activity;
  Registrar registrar;
  String mFileName;
  PreviewImpl preview;
  private FlutterView.SurfaceTextureEntry textureEntry = null;

  private Application.ActivityLifecycleCallbacks activityLifecycleCallbacks;

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "camera_support");
    channel.setMethodCallHandler(new CameraSupportPlugin(registrar,registrar.view(),registrar.activity()));
  }



  @Override
  public void onMethodCall (MethodCall call, Result result){
    String method = call.method;
    switch (method) {
      case "initialize":
        long textureId = initialize();
        result.success(textureId);
        break;
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "takePicture":
        String filePath = call.argument("filePath");
        takePicture(filePath, result);
        break;
      case "getSupportedAspectRatios":
        Set<AspectRatio> ratios = cameraHandler.getSupportedAspectRatios();
        List<HashMap<String,Integer>> convertedAspectRatios = new ArrayList<HashMap<String,Integer>>();
        for (AspectRatio aspectRatio: ratios) {
          HashMap<String, Integer> map = new HashMap<String, Integer>();
          map.put("x", aspectRatio.getX());
          map.put("y", aspectRatio.getY());
          convertedAspectRatios.add(map);
        }
        result.success(convertedAspectRatios);

        break;
      case "setAspectRatio":
        Integer x = call.argument("x");
        Integer y = call.argument("y");
        AspectRatio ratio = new AspectRatio(x,y);
        cameraHandler.setAspectRatio(ratio);
        result.success(null);
        break;
      case "getAspectRatio":
        AspectRatio aspectRatio = cameraHandler.getAspectRatio();
        HashMap<String,Integer> aspectRatioMap = new HashMap<String,Integer>();
        aspectRatioMap.put("x",aspectRatio.getX());
        aspectRatioMap.put("y",aspectRatio.getY());
        result.success(aspectRatioMap);
        break;
      case "setFlashMode":
        int flashMode = call.argument("mode");
        cameraHandler.setFlash(flashMode);
        result.success(null);
        break;
      case "getFlashMode":
        int currentFlashMode = cameraHandler.getFlash();
        result.success(currentFlashMode);
        break;
      case "dispose":
        disposeCamera();
        result.success(null);
        break;

    }
  }


  private CameraSupportPlugin(Registrar registrar, FlutterView view, Activity activity) {
    this.registrar = registrar;
    this.flutterView = view;
    this.activity = activity;

    this.activityLifecycleCallbacks = new Application.ActivityLifecycleCallbacks() {
              @Override
              public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
                Activity a = activity;
              }

              @Override
              public void onActivityStarted(Activity activity) {
                Activity a = activity;
              }

              @Override
              public void onActivityResumed(Activity activity) {
                if (activity == CameraSupportPlugin.this.activity && CameraSupportPlugin.this.cameraHandler != null) {
                  if (!CameraSupportPlugin.this.cameraHandler.isCameraOpened()) {
                    CameraSupportPlugin.this.cameraHandler.start();
                  }
                }
              }

              @Override
              public void onActivityPaused(Activity activity) {
                if (activity == CameraSupportPlugin.this.activity && CameraSupportPlugin.this.cameraHandler != null) {
                  if (CameraSupportPlugin.this.cameraHandler.isCameraOpened()) {
                    cameraHandler.stop();
                  }
                }
              }

              @Override
              public void onActivityStopped(Activity activity) {
                if (activity == CameraSupportPlugin.this.activity && CameraSupportPlugin.this.cameraHandler != null) {
                  if (CameraSupportPlugin.this.cameraHandler.isCameraOpened()) {
                    cameraHandler.stop();
                  }
                }
              }

              @Override
              public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}

              @Override
              public void onActivityDestroyed(Activity activity) {
                if (activity == CameraSupportPlugin.this.activity && CameraSupportPlugin.this.cameraHandler != null) {
                  if (CameraSupportPlugin.this.cameraHandler.isCameraOpened()) {
                    cameraHandler.stop();
                  }
                }
              }
            };

    this.activity.getApplication().registerActivityLifecycleCallbacks(this.activityLifecycleCallbacks);
  }

  public long initialize () {
    textureEntry = flutterView.createSurfaceTexture();
    textureEntry.surfaceTexture().setDefaultBufferSize(1440,1080);
    preview = new FlutterSurfaceView(this.flutterView,textureEntry);
    //if (Build.VERSION.SDK_INT < 21) {
    if (true) {
      cameraHandler = new Camera1(this, preview);
    } else if (Build.VERSION.SDK_INT < 23) {
      cameraHandler = new Camera2(this, preview, this.activity.getApplicationContext());
    } else {
      cameraHandler = new Camera2Api23(this, preview, this.activity.getApplicationContext());
    }
    CheckPermission();


    cameraHandler.setAspectRatio(Constants.DEFAULT_ASPECT_RATIO);
    cameraHandler.setAutoFocus(true);
    cameraHandler.setFlash(Constants.FLASH_ON);
    cameraHandler.setFacing(0);
    cameraHandler.start();

    setDefaultAspectRatio();

    return this.textureEntry.id();
  }

  public void disposeCamera(){
    if (cameraHandler != null) {
      cameraHandler.stop();
    }
    if (this.activity != null && this.activityLifecycleCallbacks != null) {
      this.activity
              .getApplication()
              .unregisterActivityLifecycleCallbacks(this.activityLifecycleCallbacks);
    }
  }

  public void setDefaultAspectRatio(){
    Set<AspectRatio> aspectRatios = cameraHandler.getSupportedAspectRatios();
    int previewHeight = preview.getHeight();
    int previewWidth = preview.getWidth();
    if(previewHeight == 0 || previewWidth == 0 ) return;;
    double currentRatio = previewHeight/previewWidth;
    for (AspectRatio aspectRatio: aspectRatios) {      
      double x = (double) aspectRatio.getX();
      double y = (double) aspectRatio.getY();
      double aspect =  x / y;
      if(currentRatio == aspect) cameraHandler.setAspectRatio(aspectRatio);
    }
  }

  public void CheckPermission(){
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      registrar
              .activity()
              .requestPermissions(new String[] {Manifest.permission.CAMERA}, 0);
    }
  }

  public void takePicture(String fileName, Result result)  {
    mFileName = fileName;
    cameraHandler.takePicture(result);
  }

  @TargetApi(21)
  @Override
  public void onCameraOpened() {

  }

  @Override
  public void onCameraClosed() {

  }

  @Override
  public void onPictureTaken(byte[] data) {
    writeToFile(data,mFileName);

  }

  @TargetApi(19)
  public void writeToFile(byte[] data, String fileName){
    try (FileOutputStream outputStream = new FileOutputStream(fileName)) {
      try {
        outputStream.write(data);
      } catch (IOException e) {
        e.printStackTrace();
      }
    } catch (FileNotFoundException e) {
      e.printStackTrace();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

}



