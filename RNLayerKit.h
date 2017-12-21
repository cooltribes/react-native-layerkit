#import <React/RCTBridgeModule.h>
#import <LayerKit/LayerKit.h>
#import "JSONHelper.h"
#import "MessageParts.h"
#import "LayerAuthenticate.h"
#import "LayerQuery.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "LayerConversation.h"
#import <React/RCTEventDispatcher.h>
//#import "RCTEventEmitter.h"
#import <React/RCTEventEmitter.h>
@import UserNotifications;

@interface RNLayerKit : RCTEventEmitter <RCTBridgeModule, UNUserNotificationCenterDelegate>
+ (nonnull instancetype)bridgeWithLayerAppID:(nonnull NSURL *)layerAppID bridge:(RCTBridge *)bridge apiUrl:(NSString *)apiUrl;
- (void)didReceiveTypingIndicator:(NSNotification *)notification;
- (void)updateRemoteNotificationDeviceToken:(nullable NSData *)deviceToken;
- (void)setPresenceStatusAway;
- (void)setPresenceStatusAvailable;
@property (nonatomic) LYRConversation *conversation;
@end
