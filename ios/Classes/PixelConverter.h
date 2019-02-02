#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>
#import <AVFoundation/AVFoundation.h>
#import <Accelerate/Accelerate.h>
#import <CoreMotion/CoreMotion.h>

@interface PixelConverter : NSObject

@property(readonly) CVPixelBufferRef volatile latestPixelBuffer;
@property(nonatomic) vImage_Buffer destinationBuffer;
@property(nonatomic) vImage_Buffer conversionBuffer;
@property(readonly, nonatomic) CGSize previewSize;

- (CVPixelBufferRef) convert: (CVPixelBufferRef)sourceBuffer;
- (CVPixelBufferRef) convertYUVImageToBGRA:(CVPixelBufferRef)pixelBuffer;

- (instancetype)initWithWidth: (CGFloat)width
                  height:(CGFloat)height;
@end
