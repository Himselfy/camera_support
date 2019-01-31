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
        //result.success(aspectRatioMap);
        break;
    case "setFlashMode":
        var flashMode = (call.arguments as! NSDictionary)["mode"];
        //cameraHandler.setFlash(flashMode);
        result(nil);
        break;
    case "getFlashMode":
        //var currentFlashMode = cameraHandler.getFlash();
        //result.success(currentFlashMode);
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
public class CameraHandler : NSObject, FlutterTexture, AVCaptureVideoDataOutputSampleBufferDelegate {
    var captureSession: AVCaptureSession?
    var captureDevice: AVCaptureDevice?
    var captureInput: AVCaptureDeviceInput?
    var captureOutput: AVCapturePhotoOutput?
    var videoOutput: AVCaptureVideoDataOutput?
    var previewView: UIView
    var previewLayer: AVCaptureVideoPreviewLayer?
    var pixelBuffer: CVPixelBuffer?
    var onFrameAvailable: (() -> Void)?
    var tempBuff: CVPixelBuffer?
    var outputSampleBuffer : CMSampleBuffer? = nil
    
    public func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        let tempImageBuffer = CMSampleBufferGetImageBuffer(outputSampleBuffer!);
        if outputSampleBuffer == nil { return nil }
        let imageBuffer: CVImageBuffer = CMSampleBufferGetImageBuffer(outputSampleBuffer!)!
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let context:CIContext = CIContext.init(options: nil)

        let width = CVPixelBufferGetWidth(tempImageBuffer!);
        let height = CVPixelBufferGetHeight(tempImageBuffer!);

        
        if pixelBuffer == nil {
            CVPixelBufferCreate(
                kCFAllocatorDefault,
                CVPixelBufferGetWidth(tempImageBuffer!),
                CVPixelBufferGetHeight(tempImageBuffer!),
                kCVPixelFormatType_32BGRA,//CVPixelBufferGetPixelFormatType(tempImageBuffer!),
                CVBufferGetAttachments(tempImageBuffer!, .shouldPropagate),
                &(self.pixelBuffer))
            //CVPixelBufferCreate(kCFAllocatorDefault, 1200, 1200, kCVPixelFormatType_32BGRA, nil, &(self.pixelBuffer))
        }
        
        
        context.render(ciImage, to: pixelBuffer!)
        return Unmanaged.passRetained(pixelBuffer!)

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
    
    func configurePreview() throws {
 
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession!)
        self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        previewView.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = previewView.frame
        
        
    }
}




