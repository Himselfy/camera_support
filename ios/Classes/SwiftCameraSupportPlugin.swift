import Flutter
import UIKit
import Accelerate
import AVFoundation
import CoreMotion
import libkern

@available(iOS 10.0, *)
public class SwiftCameraSupportPlugin: NSObject, FlutterPlugin {
  
    var registry: FlutterTextureRegistry?;
    var messenger: FlutterBinaryMessenger?;
    var cameraHandler: CameraHandler?;
    
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "camera_support", binaryMessenger: registrar.messenger())
    let instance = SwiftCameraSupportPlugin(registry: registrar.textures(), messenger: registrar.messenger())
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
    
  
  init(registry: FlutterTextureRegistry?, messenger: FlutterBinaryMessenger?) {
    super.init();
    self.registry = registry;
    self.messenger = messenger;
  }
    

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch(call.method){
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            break;
    case "initialize":
        self.cameraHandler = CameraHandler()
        let test = registry!.register(TestTexture())
        let textureId = registry?.register(self.cameraHandler!);
        
        self.cameraHandler?.onFrameAvailable = {
            self.registry?.textureFrameAvailable(textureId!)
        }
        result(textureId!);
        break;
    case "takePicture":
        var path = (call.arguments as! NSDictionary)["filePath"] as! String
        cameraHandler?.takePicture(path: path)
        break;
    case "getSupportedAspectRatios":
        //result.success(convertedAspectRatios);
        break;
    case "setAspectRatio":
        var x = (call.arguments as! NSDictionary)["x"];
        var y = (call.arguments as! NSDictionary)["y"];
        result(nil);
        break;
    case "getAspectRatio":
        var params = ["x": 4, "y": 3];
        result(params)
        break;
    case "setFlashMode":
        print(call.arguments)
        let flashMode = (call.arguments as! NSDictionary)["mode"];
        cameraHandler?.setFlashMode(mode: flashMode as! Int);
        result(nil);
        break;
    case "getFlashMode":
        var currentFlashMode = cameraHandler!.getFlashMode();
        result(currentFlashMode);
        break;
    case "dispose":
        //disposeCamera();
        //result.success(null);
        break;
    default:
        break;
    }
    
  }
}

public class TestTexture : NSObject, FlutterTexture {
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        return nil
    }
    
    
}

@available(iOS 10.0, *)
public class CameraHandler : NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession?
    var captureDevice: AVCaptureDevice?
    var captureInput: AVCaptureDeviceInput?
    var captureOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    var previewView: UIView
    var currentPhotoFilePath: String = ""
    var previewLayer: AVCaptureVideoPreviewLayer?
    var previewPixelBuffer: CVPixelBuffer?
    var onFrameAvailable: (() -> Void)?
    var outputSampleBuffer : CMSampleBuffer? = nil
    var context :CIContext = CIContext.init(options: nil)
    var converter : PixelConverter = PixelConverter.init(size: 1280, height: 720)
    var flashMode : AVCaptureDevice.FlashMode = AVCaptureDevice.FlashMode.auto
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if outputSampleBuffer == nil { return nil }
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(outputSampleBuffer!)!
        var result = converter.convert(imageBuffer)
        return result;
        
    }
    
    public func setFlashMode(mode: Int){
        if mode == 0 { flashMode = AVCaptureDevice.FlashMode.off }
        if mode == 1 { flashMode = AVCaptureDevice.FlashMode.on }
        if mode == 2 { flashMode = AVCaptureDevice.FlashMode.on }
        if mode == 3 { flashMode = AVCaptureDevice.FlashMode.auto}
    }
    
    public func getFlashMode() -> Int {
        switch flashMode {
        case AVCaptureDevice.FlashMode.on:
            return 1;
        case AVCaptureDevice.FlashMode.off:
            return 0;
        case AVCaptureDevice.FlashMode.auto:
            return 3;
        default:
            return 3;
        }
    }
    
    override init(){
        previewView = UIView()
        super.init();
        
        do {
            configureSession()
            try configureCameraDevice()
            try configureDeviceInput()
            configureDeviceOutput()
            try configurePreview()
            self.captureSession?.startRunning()
        }
            
        catch {
            return
        }
    }
    

    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.outputSampleBuffer = sampleBuffer
        
        switch UIDevice.current.orientation {
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .portrait:
                connection.videoOrientation = .portrait
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            default:
                connection.videoOrientation = .portrait
        }
        
        if onFrameAvailable != nil {
            onFrameAvailable?()
        }
        
    }
    
    func configureSession() {
        self.captureSession = AVCaptureSession()
    }
    
    func configureCameraDevice() throws {
        let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        let cameras = (session.devices.compactMap { $0 });
        
        for camera in cameras {
            if camera.position == .back {
                self.captureDevice = camera
                
                try camera.lockForConfiguration()
                camera.focusMode = .autoFocus
                camera.flashMode = .on
                camera.unlockForConfiguration()
            }
        }
    }
    
    func configureDeviceInput() throws {
        self.captureInput = try AVCaptureDeviceInput(device: self.captureDevice!)
        if self.captureSession!.canAddInput(self.captureInput!) { captureSession!.addInput(self.captureInput!) }
    }
    
    func configureDeviceOutput() {
        self.captureOutput = AVCapturePhotoOutput()
        if self.captureSession!.canAddOutput(self.captureOutput!) { captureSession!.addOutput(self.captureOutput!) }
        self.captureOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecJPEG])], completionHandler: nil)
        
        self.videoOutput = AVCaptureVideoDataOutput()
        
        self.videoOutput!.setSampleBufferDelegate(self, queue: DispatchQueue(label: "preview buffer"))
        if self.captureSession!.canAddOutput(self.videoOutput!) { self.captureSession!.addOutput(self.videoOutput!) }
        
    }
    
    func takePicture(path: String){
        let settings = AVCapturePhotoSettings()
        settings.flashMode = self.flashMode
        currentPhotoFilePath = path
        self.captureOutput?.capturePhoto(with: settings , delegate: self)
    }
    
    public func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?,
                        resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Swift.Error?) {
        
       if let buffer = photoSampleBuffer, let data = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: buffer, previewPhotoSampleBuffer: nil){
            do {
                try data.write(to: URL(fileURLWithPath: self.currentPhotoFilePath), options: .atomic)
            }
            catch { return }
        }
    }
    
    func configurePreview() throws {
 
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        previewView.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = previewView.frame
        
        
    }
    


    
}



