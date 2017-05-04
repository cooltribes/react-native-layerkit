#import "RCTBridgeModule.h"
#import <LayerKit/LayerKit.h>
#import "JSONHelper.h"
#import "LayerAuthenticate.h"
#import "LayerQuery.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"
#import "RCTEventEmitter.h"

@interface RNLayerKit : RCTEventEmitter <RCTBridgeModule>
+ (nonnull instancetype)bridgeWithLayerAppID:(nonnull NSURL *)layerAppID bridge:(RCTBridge *)bridge;
- (void)didReceiveTypingIndicator:(NSNotification *)notification;
- (void)updateRemoteNotificationDeviceToken:(nullable NSData *)deviceToken;
@end
