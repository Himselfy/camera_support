#import "PixelConverter.h"
#import <libkern/OSAtomic.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <CoreMotion/CoreMotion.h>



@implementation PixelConverter

- (instancetype)initWithSize:(CGFloat)width height:(CGFloat)height {
    
    _previewSize = CGSizeMake(width,height);
    
    vImageBuffer_Init(&_destinationBuffer, _previewSize.width, _previewSize.height, 32,
                      kvImageNoFlags);
    vImageBuffer_Init(&_conversionBuffer, _previewSize.width, _previewSize.height, 32,
                      kvImageNoFlags);
    return self;
}

- (CVPixelBufferRef) convert: (CVPixelBufferRef)sourceBuffer {
    
    CFRetain(sourceBuffer);
    CVPixelBufferRef old = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(old, sourceBuffer, (void **)&_latestPixelBuffer)) {
        old = _latestPixelBuffer;
    }
    if (old != nil) {
        CFRelease(old);
    }
    
    CVPixelBufferRef pixelBuffer = _latestPixelBuffer;
    while (!OSAtomicCompareAndSwapPtrBarrier(pixelBuffer, nil, (void **)&_latestPixelBuffer)) {
        pixelBuffer = _latestPixelBuffer;
    }
    return [self convertYUVImageToBGRA:pixelBuffer];
}

- (CVPixelBufferRef)convertYUVImageToBGRA:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    
    vImage_YpCbCrToARGB infoYpCbCrToARGB;
    vImage_YpCbCrPixelRange pixelRange;
    pixelRange.Yp_bias = 16;
    pixelRange.CbCr_bias = 128;
    pixelRange.YpRangeMax = 235;
    pixelRange.CbCrRangeMax = 240;
    pixelRange.YpMax = 235;
    pixelRange.YpMin = 16;
    pixelRange.CbCrMax = 240;
    pixelRange.CbCrMin = 16;
    
    vImageConvert_YpCbCrToARGB_GenerateConversion(kvImage_YpCbCrToARGBMatrix_ITU_R_601_4, &pixelRange,
                                                  &infoYpCbCrToARGB, kvImage420Yp8_CbCr8,
                                                  kvImageARGB8888, kvImageNoFlags);
    
    vImage_Buffer sourceLumaBuffer;
    sourceLumaBuffer.data = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    sourceLumaBuffer.height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0);
    sourceLumaBuffer.width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0);
    sourceLumaBuffer.rowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0);
    
    vImage_Buffer sourceChromaBuffer;
    sourceChromaBuffer.data = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1);
    sourceChromaBuffer.height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1);
    sourceChromaBuffer.width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1);
    sourceChromaBuffer.rowBytes = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1);
    
    vImageConvert_420Yp8_CbCr8ToARGB8888(&sourceLumaBuffer, &sourceChromaBuffer, &_destinationBuffer,
                                         &infoYpCbCrToARGB, NULL, 255,
                                         kvImagePrintDiagnosticsToConsole);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
    CVPixelBufferRelease(pixelBuffer);
    
    const uint8_t map[4] = {3, 2, 1, 0};
    vImagePermuteChannels_ARGB8888(&_destinationBuffer, &_conversionBuffer, map, kvImageNoFlags);
    
    CVPixelBufferRef newPixelBuffer = NULL;
    CVPixelBufferCreateWithBytes(NULL, _conversionBuffer.width, _conversionBuffer.height,
                                 kCVPixelFormatType_32BGRA, _conversionBuffer.data,
                                 _conversionBuffer.rowBytes, NULL, NULL, NULL, &newPixelBuffer);
    
    return newPixelBuffer;
}


@end

