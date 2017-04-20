#import "RCTBridgeModule.h"
#import <LayerKit/LayerKit.h>
#import "JSONHelper.h"
#import "LayerAuthenticate.h"
#import "LayerQuery.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTEventDispatcher.h"

@interface RNLayerKit : NSObject <RCTBridgeModule>
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
+ (void)initializeLayer:(LYRClient *)layerInitialized;
+ (void)objectsDidChange:(NSArray *)changes;
+ (nonnull instancetype)bridgeWithLayerAppID:(nonnull NSURL *)layerAppID;
- (void)didReceiveTypingIndicator:(NSNotification *)notification;
- (void)updateRemoteNotificationDeviceToken:(nullable NSData *)deviceToken;
@end
