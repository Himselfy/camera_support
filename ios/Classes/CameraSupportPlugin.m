#import "CameraSupportPlugin.h"
#import <camera_support/camera_support-Swift.h>

@implementation CameraSupportPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCameraSupportPlugin registerWithRegistrar:registrar];
}
@end
