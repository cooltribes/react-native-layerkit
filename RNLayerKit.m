#import "RNLayerKit.h"
NSData *_deviceToken;
LYRClient *_layerClient;

@implementation RNLayerKit{
    NSString *_appID;
    JSONHelper *_jsonHelper;
    NSString *_userID;
    NSString *_header;
    NSString *_apiUrl;
}

//@synthesize bridge = _bridge;

// - (id)init
// {
//     NSLog(@"LayerBridge 1 not init");
//     NSLog(@"self.bridge 2 %@", self.bridge);
//     if ((self = [super init])) {
//         NSLog(@"LayerBridge init");
//         _jsonHelper = [JSONHelper new];
//         [[NSNotificationCenter defaultCenter] addObserver:self
//                                                  selector:@selector(receivedNotification:)
//                                                      name:@"RNLayerKitNotification"
//                                                    object:nil];
//     }
//     NSLog(@"self.bridge 3 %@", self.bridge);
//     return self;
// }

+ (nonnull instancetype)bridgeWithLayerAppID:(nonnull NSURL *)layerAppID bridge:(RCTBridge *)bridge apiUrl:(NSString *)apiUrl
{
    NSLog(@"bridgeWithLayerAppID");
    //_bridge = bridge;
    return [[self alloc] initWithLayerAppID:layerAppID bridge:bridge apiUrl:apiUrl];
}

- (id)initWithLayerAppID:(nonnull NSURL *)layerAppID bridge:(RCTBridge *)bridge apiUrl:(NSString *)apiUrl
{
    NSLog(@"initWithLayerAppID");

    self = [super init];
    self.bridge = bridge;
    _apiUrl = apiUrl;
    NSLog(@"self.bridge 5 %@", self.bridge);
    if (self) {
         NSLog(@"initWithLayerAppID self");
        _jsonHelper = [JSONHelper new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:@"RNLayerKitNotification"
                                                   object:nil];
        LYRClientOptions *clientOptions = [LYRClientOptions new];
        clientOptions.synchronizationPolicy = 1;
        _layerClient = [LYRClient clientWithAppID:layerAppID delegate:self options:clientOptions];
    }
    return self;
}


//- (dispatch_queue_t)methodQueue
//{
//  return dispatch_queue_create("com.schoolstatus.LayerCLientQueue", DISPATCH_QUEUE_SERIAL);
//}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"LayerEvent"];
}

RCT_EXPORT_METHOD(connect:(NSString*)appIDstr header:(NSString*)header
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    _header = header;
    // NSURL *appID = [NSURL URLWithString:appIDstr];
    // LYRClientOptions *clientOptions = [LYRClientOptions new];
    // clientOptions.synchronizationPolicy = 1;
    // //_deviceToken = deviceToken;
    // if (!_layerClient) {
    //     NSLog(@"No Layer Client");
    //     _layerClient = [LYRClient clientWithAppID:appID delegate:self options:clientOptions];
    // }
    //[_layerClient setDelegate:self];
    if (!_layerClient.isConnected) {
        [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Failed to connect to Layer: %@", error);
                //RCTLogInfo(@"Failed to connect to Layer: %@", error);
                reject(@"no_events", @"There were no events", nil);
            } else {
                NSLog(@"Connected to Layer!");
                RCTLogInfo(@"Connected to Layer!");
                if(_deviceToken)
                    [self updateRemoteNotificationDeviceToken:_deviceToken];
                NSString *thingToReturn = @"YES";
                resolve(thingToReturn);
            }
        }];
    } else {
        NSLog(@"Connected to Layer!");
        RCTLogInfo(@"Connected to Layer!");
        if(_deviceToken)
            [self updateRemoteNotificationDeviceToken:_deviceToken];
        NSString *thingToReturn = @"YES";
        resolve(thingToReturn);
    }
    
    
    
    
}

RCT_EXPORT_METHOD(disconnect)
{
    //[_layerClient disconnect];
    //NSError *error;
    ////BOOL success = [_layerClient setPresenceStatus:LYRIdentityPresenceStatusOffline error:&error];
    //if (!success) {
    //    NSLog(@"Failed to setPresenceStatus: %@", error);
        // handle error here
    //} else {
    //    NSLog(@"setPresenceStatus to Offline"); 
   // }
    [_layerClient deauthenticateWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Failed to deauthenticate user: %@", error);
        } else {
            NSLog(@"User was deauthenticated");
            //[_layerClient disconnect];
        }
    }];
    
}



RCT_EXPORT_METHOD(sendMessageToUserIDs:(NSString*)messageText userIDs:(NSArray*)userIDs
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    // Declares a MIME type string
    static NSString *const MIMETypeTextPlain = @"text/html";
    static NSString *const MIMETypeImagePNG = @"image/png";
    // Create a distinct conversation
    
    
    if (!_layerClient.isConnected) {
        [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Failed to connect to Layer: %@", error);
                RCTLogInfo(@"Failed to connect to Layer: %@", error);
                reject(@"no_events", @"There were no events", error);
            } else {
                NSError *errorConversation = nil;
                NSSet *participants = [NSSet setWithArray: userIDs];
                LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
                if ([userIDs count] >= 2)
                    conversationOptions.distinctByParticipants = NO;
                else
                    conversationOptions.distinctByParticipants = YES;
                LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
                if (errorConversation && errorConversation.code == LYRErrorDistinctConversationExists) {
                    conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
                }
                
                NSError *error = nil;
                
                NSData *messageData = [messageText dataUsingEncoding:NSUTF8StringEncoding];
                
                LYRMessagePart *messagePart = [LYRMessagePart messagePartWithMIMEType:MIMETypeTextPlain data:messageData];
                
                // Creates and returns a new message object with the given conversation and array of message parts
                NSString *pushMessage= [NSString stringWithFormat:@"%@", messageText];
                LYRPushNotificationConfiguration *defaultConfiguration = [LYRPushNotificationConfiguration new];
                defaultConfiguration.title = [[_layerClient authenticatedUser] displayName];
                defaultConfiguration.alert = pushMessage;
                defaultConfiguration.category = @"category_lqs";
                defaultConfiguration.sound = @"layerbell.caf";
                
                LYRMessageOptions *messageOptions = [LYRMessageOptions new];
                messageOptions.pushNotificationConfiguration = defaultConfiguration;
                LYRMessage *message = [_layerClient newMessageWithParts:@[messagePart] options:messageOptions error:nil];
                // Sends the specified message
                BOOL success = [conversation sendMessage:message error:&error];
                
                if(success){
                    RCTLogInfo(@"Layer Message sent to %@", userIDs);
                    //TODO: return conversation
                    NSString *thingToReturn = @"YES";
                    resolve(thingToReturn);
                }
                else {
                    //id retErr = RCTMakeAndLogError(@"Error sending Layer message",error,NULL);
                    //NSError *error = retErr;
                    NSLog(@"Error Sending Layer Message %@", error);
                    reject(@"no_events", @"Error creating conversastion", nil);
                }
            }
        }];
    } else {
        NSError *errorConversation = nil;
        NSSet *participants = [NSSet setWithArray: userIDs];
        LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
        if ([userIDs count] >= 2)
            conversationOptions.distinctByParticipants = NO;
        else
            conversationOptions.distinctByParticipants = YES;
        LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
        if (errorConversation && errorConversation.code == LYRErrorDistinctConversationExists) {
            conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
        }
        
        NSError *error = nil;
        NSData *messageData = [messageText dataUsingEncoding:NSUTF8StringEncoding];
        LYRMessagePart *messagePart = [LYRMessagePart messagePartWithMIMEType:MIMETypeTextPlain data:messageData];
        
        // Creates and returns a new message object with the given conversation and array of message parts
        NSString *pushMessage= [NSString stringWithFormat:@"%@", messageText];
        
        LYRPushNotificationConfiguration *defaultConfiguration = [LYRPushNotificationConfiguration new];
        defaultConfiguration.title = [[_layerClient authenticatedUser] displayName];
        defaultConfiguration.alert = pushMessage;
        defaultConfiguration.category = @"category_lqs";
        defaultConfiguration.sound = @"layerbell.caf";
        LYRMessageOptions *messageOptions = [LYRMessageOptions new];
        messageOptions.pushNotificationConfiguration = defaultConfiguration;
        LYRMessage *message = [_layerClient newMessageWithParts:@[messagePart] options:messageOptions error:nil];
        // Sends the specified message
        BOOL success = [conversation sendMessage:message error:&error];
        
        if(success){
            RCTLogInfo(@"Layer Message sent to %@", userIDs);
            //TODO: return conversation
            NSString *thingToReturn = @"YES";
            resolve(thingToReturn);
        }
        else {
            //id retErr = RCTMakeAndLogError(@"Error sending Layer message",error,NULL);
            //NSError *error = retErr;
            NSLog(@"Error Sending Layer Message %@", error);
            reject(@"no_events", @"Error creating conversastion", nil);
        }
    }
    
}

RCT_EXPORT_METHOD(getConversations:(int)limit offset:(int)offset
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    LayerQuery *query = [LayerQuery new];
    NSError *queryError;
    id allConvos = [query fetchConvosForClient:_layerClient limit:limit offset:offset error:queryError];
    if(queryError){
        id retErr = RCTMakeAndLogError(@"Error getting Layer conversations",queryError,NULL);
        NSError *error = retErr;
        reject(@"no_events", @"Error creating conversastion", error);
        //callback(@[retErr,[NSNull null]]);
    }
    else{
        JSONHelper *helper = [JSONHelper new];
        NSArray *retData = [helper convertConvosToArray:allConvos];
        NSString *thingToReturn = @"YES";
        resolve(@[thingToReturn,retData]);
    }
}

RCT_EXPORT_METHOD(setConversationTitle:(NSString*)convoID title:(NSString*)title
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *conversation = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
      reject(@"no_events", @"Error getting conversation", err);
    } else {
      [conversation setValue:title forMetadataAtKeyPath:@"title"];
      NSString *thingToReturn = @"YES";
      NSLog(@"conversation %@", conversation);
      resolve(thingToReturn);
    }
}
RCT_EXPORT_METHOD(getMessages:(NSString*)convoID userIDs:(NSArray*)userIDs limit:(int)limit offset:(int)offset
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (convoID){
        LayerQuery *query = [LayerQuery new];
        NSError *queryError;
        NSOrderedSet *convoMessages = [query fetchMessagesForConvoId:convoID client:_layerClient limit:limit offset:offset error:queryError];
        if(queryError){
            id retErr = RCTMakeAndLogError(@"Error getting Layer messages",queryError,NULL);
            NSError *error = retErr;
            reject(@"no_events", @"Error creating conversastion", error);
        }
        else{
            JSONHelper *helper = [JSONHelper new];
            NSArray *retData = [helper convertMessagesToArray:convoMessages];
            NSString *thingToReturn = @"YES";
            // NSLog(@"entro en mensajes de conversation")
            // for (LYRMessage *msg in convoMessages) {
            //     NSError *errorMsg = nil;
            //     NSLog(@"mensaje con conversation: %@",msg);
            //     BOOL success = [msg markAsRead:&errorMsg];
            //     if (success) {
            //         NSLog(@'Message successfully marked as read');
            //     } else {
            //         NSLog(@'Failed to mark message as read with error %@', errorMsg);
            //     }
            // }
            resolve(@[thingToReturn,retData]);
        }
    } else {
        NSError *errorConversation = nil;
        NSLog(@"userIDs: %@", userIDs);
        NSSet *participants = [NSSet setWithArray: userIDs];
        LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
        if ([userIDs count] >= 2)
            conversationOptions.distinctByParticipants = NO;
        else
            conversationOptions.distinctByParticipants = YES;
        LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
        NSLog(@"No conversation");
        NSLog(@"errorConversation %@", errorConversation);
        if (errorConversation && errorConversation.code == LYRErrorDistinctConversationExists) {
            conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
            NSLog(@"old conversation");
        }
        if (conversation){
            LayerQuery *query = [LayerQuery new];
            NSError *queryError;
            NSLog(@"old conversation get messages %@", conversation);
            NSOrderedSet *convoMessages = [query fetchMessagesForConvoId:conversation client:_layerClient limit:limit offset:offset error:queryError];
            if(queryError){
                id retErr = RCTMakeAndLogError(@"Error getting Layer messages",queryError,NULL);
                NSError *error = retErr;
                reject(@"no_events", @"Error creating conversastion", error);
            }
            else{
                JSONHelper *helper = [JSONHelper new];
                NSArray *retData = [helper convertMessagesToArray:convoMessages];
                NSString *thingToReturn = @"YES";
                // for (LYRMessage *msg in convoMessages) {
                //     NSError *errorMsg = nil;
                //     NSLog(@"mensaje no conversation: %@",msg);
                //     BOOL success = [msg markAsRead:&errorMsg];
                //     if (success) {
                //         NSLog(@'Message successfully marked as read');
                //     } else {
                //         NSLog(@'Failed to mark message as read with error %@', errorMsg);
                //     }
                // }
                resolve(@[thingToReturn,retData,[conversation.identifier absoluteString]]);
            }
        }
    }
}

RCT_EXPORT_METHOD(markAllAsRead:(NSString*)convoID resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    //NSLog(@"entro en markAllAsRead: %@", convoID);
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        [self sendErrorEvent:err];
    }
    else {
        NSError *error;
        //NSLog(@"conversation on mark all as read: %@",thisConvo);
        BOOL success = [thisConvo markAllMessagesAsRead:&error];
        if(success){
            RCTLogInfo(@"Layer Messages marked as read");
            NSError *queryError;
            NSInteger count = [query fetchMessagesCount:_userID client:_layerClient error:queryError];
            resolve(@[[NSNumber numberWithInteger:count],@YES]);
        }
        else {
            if (thisConvo != NULL) {
                id retErr = RCTMakeAndLogError(@"Error marking messages as read ",error,NULL);
                NSError *error = retErr;
                reject(@"no_events", @"Error mark all as read", error);
            }
        }
    }
    
    
}

RCT_EXPORT_METHOD(sendTypingBegin:(NSString*)convoID
                resolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        id retErr = RCTMakeAndLogError(@"Error getting conversation on sendTypingBegin ",err,NULL);
        NSError *error = retErr;
        reject(@"no_events", @"Error getting conversation on sendTypingBegin", error);
    }
    else {
        [thisConvo sendTypingIndicator:LYRTypingIndicatorActionBegin];
        NSLog(@"LYRTypingIndicatorActionBegin");
        NSString *thingToReturn = @"YES";
        resolve(thingToReturn);
    }
}

RCT_EXPORT_METHOD(sendTypingEnd:(NSString*)convoID 
                resolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        id retErr = RCTMakeAndLogError(@"Error getting conversation on sendTypingEnd ",err,NULL);
        NSError *error = retErr;
        reject(@"no_events", @"Error getting conversation on sendTypingEnd", error);
    }
    else {
        [thisConvo sendTypingIndicator:LYRTypingIndicatorActionFinish];
        NSLog(@"LYRTypingIndicatorActionFinish");
        NSString *thingToReturn = @"YES";
        resolve(thingToReturn);
    }
}

RCT_EXPORT_METHOD(registerForTypingEvents)
{
    NSLog(@"registerForTypingEvents");
    // Registers and object for typing indicator notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didReceiveTypingIndicator:)
                                                 name:LYRConversationDidReceiveTypingIndicatorNotification
                                               object:nil];
}

RCT_EXPORT_METHOD(unregisterForTypingEvents)
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRConversationDidReceiveTypingIndicatorNotification object:nil];
}
#pragma mark - Authentication
RCT_EXPORT_METHOD(authenticateLayerWithUserID:(NSString *)userID header:(NSString *)header
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (!_layerClient.isConnected) {
        NSLog(@"Layer is not connected");
    } else {
        NSLog(@"Layer is connected");
    }
    _userID = userID;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRConversationDidReceiveTypingIndicatorNotification object:nil];
    LayerAuthenticate *lAuth = [LayerAuthenticate new];
    NSLog(@"Layer authenticated");
    [lAuth authenticateLayerWithUserID:userID header:header layerClient:_layerClient completion:^(NSError *error) {
        if (!error) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(didReceiveTypingIndicator:)
                                             name:LYRConversationDidReceiveTypingIndicatorNotification
                                           object:nil];
            LayerQuery *query = [LayerQuery new];
            NSError *queryError;
            NSInteger count = [query fetchMessagesCount:userID client:_layerClient error:queryError];
            NSString *thingToReturn = @"YES";
            NSError *errorStatus;
            BOOL success = [_layerClient setPresenceStatus:LYRIdentityPresenceStatusAvailable error:&errorStatus];
            if (!success) {
                NSLog(@"Failed to setPresenceStatus: %@", errorStatus);
                // handle error here
            } else {
                NSLog(@"setPresenceStatus to Available"); 
            }           
            resolve(@[thingToReturn,[NSNumber numberWithInteger:count]]);
        }
        else{
            //id retErr = RCTMakeAndLogError(@"Error logging in",error,NULL);
            //NSError *error = retErr;
            reject(@"no_events", @"Error logging in", error);
        }
    }];
}

#pragma mark - Register for Push Notif
- (void) receivedNotification:(NSNotification *) notification
{
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.
    NSLog (@"Enter to receivedNotification!");
    if ([[notification name] isEqualToString:@"RNLayerKitNotification"])
    {
        NSLog (@"Successfully received the test notification!");
        NSDictionary *userInfo = notification.userInfo;
        NSData *myToken = [userInfo objectForKey:@"deviceToken"];
        [self updateRemoteNotificationDeviceToken:myToken];
    }
}
-(void)updateRemoteNotificationDeviceToken:(NSData*)deviceToken
{
    // if we haven't initialize our client, then save the token for later
    NSLog (@"Enter on updateRemoteNotificationDeviceToken");
    if(!_layerClient){
        _deviceToken=deviceToken;
    }
    else{
        NSError *error;
        BOOL success = [_layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
        if (success) {
            NSLog(@"Application did register for remote notifications: %@", deviceToken);
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                         body:@{@"source":@"LayerClient",@"type": @"didRegisterForRemoteNotificationsWithDeviceToken"}];
        } else {
            NSLog(@"Error updating Layer device token for push:%@", error);
            //[self sendErrorEvent:error];
        }
    }
    
}
#pragma mark - Error Handle
-(void)sendErrorEvent:(NSError*)error{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"error",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
#pragma mark - Layer Client Delegate
- (void)layerClient:(LYRClient *)client didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"PUSH ERROR: %@", error);
}
- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    
    NSLog(@"didAuthenticateAsUserID %@", userID);
    NSLog(@"self.bridge.eventDispatcher %@", self.bridge.eventDispatcher);
    NSLog(@"self.bridge %@", self.bridge);
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient",@"type": @"didAuthenticateAsUserID", @"data":@{@"userID":userID}}];
}
- (void)layerClient:(LYRClient *)client didFailOperationWithError:(NSError *)error
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFailOperationWithError",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
- (void)layerClient:(LYRClient *)client didFailSynchronizationWithError:(NSError *)error
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFailSynchronizationWithError",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
- (void)layerClient:(LYRClient *)client didFinishContentTransfer:(LYRContentTransferType)contentTransferType ofObject:(id)object
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFinishContentTransfer"}];
}
- (void)layerClient:(LYRClient *)client didFinishSynchronizationWithChanges:(NSArray *)changes
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didFinishSynchronizationWithChanges"}];
}
- (void)layerClient:(LYRClient *)client didLoseConnectionWithError:(NSError *)error
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didLoseConnectionWithError", @"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
- (void)layerClient:(LYRClient *)client didReceiveAuthenticationChallengeWithNonce:(NSString *)nonce
{
    NSLog(@"Layer Client did receive an authentication challenge with nonce=%@", nonce);
    NSLog(@"Header: %@",_header);
    if (_layerClient.authenticatedUser)
        _userID = _layerClient.authenticatedUser.userID;
    NSLog(@"LayerUserID: %@",_userID);
    //if (_header){
        LayerAuthenticate *lAuth = [LayerAuthenticate new];
        [lAuth authenticationChallenge:_userID layerClient:_layerClient nonce:nonce header:_header apiUrl:_apiUrl completion:^(NSError *error) {
            if (!error) {
                NSError *errorStatus;
                BOOL success = [_layerClient setPresenceStatus:LYRIdentityPresenceStatusAvailable error:&errorStatus];
                if (!success) {
                    NSLog(@"Failed to setPresenceStatus: %@", errorStatus);
                    // handle error here
                } else {
                    NSLog(@"setPresenceStatus to Available"); 
                }
                [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                             body:@{@"source":@"LayerClient", @"type": @"didReceiveAuthenticationChallengeWithNonce"}];
            }
            else{
                NSLog(@"Error %@",error);
                [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                             body:@{@"source":@"LayerClient", @"type": @"didReceiveAuthenticationChallengeWithNonce"}];
            }
        }];
    //}
    
}
- (void)layerClient:(LYRClient *)client objectsDidChange:(NSArray *)changes;
{
    NSLog(@"objectsDidChange %@", changes);
    //NSLog(@"self.bridge.eventDispatcher %@", self.bridge.eventDispatcher);
    //NSLog(@"self.bridge %@", self.bridge);
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
         body:@{@"source":@"LayerClient",
                @"type": @"objectsDidChange",
                @"data":[_jsonHelper convertChangesToArray:changes]}];
    NSLog(@"Salio objectsDidChange");
}
- (void)layerClient:(LYRClient *)client willAttemptToConnect:(NSUInteger)attemptNumber afterDelay:(NSTimeInterval)delayInterval maximumNumberOfAttempts:(NSUInteger)attemptLimit
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type":@"willAttemptToConnect", @"data":@{@"attemptNumber":@(attemptNumber), @"delayInterval":@(delayInterval), @"attemptLimit":@(attemptLimit)}}];
}
- (void)layerClient:(LYRClient *)client willBeginContentTransfer:(LYRContentTransferType)contentTransferType ofObject:(id)object withProgress:(LYRProgress *)progress
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"willBeginContentTransfer"}];
}
- (void)layerClientDidConnect:(LYRClient *)client{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"layerClientDidConnect"}];
}
- (void)layerClientDidDeauthenticate:(LYRClient *)client
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"layerClientDidDeauthenticate"}];
}
- (void)layerClientDidDisconnect:(LYRClient *)client
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"layerClientDidDisconnect"}];
}
// + (void)objectsDidChange:(NSArray *)changes
// {
//     NSLog(@"objectsDidChange %@", changes);
//     [bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                                  body:@{@"source":@"LayerClient",
//                                                         @"type": @"objectsDidChange",
//                                                         @"data":[_jsonHelper convertChangesToArray:changes]}];
//     //NSLog(@"Salio objectsDidChange");
// }
// + (void)initializeLayer:(LYRClient *)layerInitialized
// {
//     NSLog(@"Layer Client initialize %@", layerInitialized);
//     _layerClient = layerInitialized;   
// }
// + (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
// {
//     NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken Layer: %@", deviceToken);
//     _deviceToken = deviceToken;
//     //[self updateRemoteNotificationDeviceToken:deviceToken];
//     // NSError *error;
//     // BOOL success = [LYRClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
//     // if (success) {
//     // NSLog(@"Application did register for remote notifications");
//     // } else {
//     // NSLog(@"Error updating Layer device token for push:%@", error);
//     // }
// }

// - (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
// {
//    NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken: %@", deviceToken);
// //   NSError *error;
// //   BOOL success = [LYRClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
// //   if (success) {
// //     NSLog(@"Application did register for remote notifications");
// //   } else {
// //     NSLog(@"Error updating Layer device token for push:%@", error);
// //   }

// }

#pragma mark - Typing Indicator
- (void)didReceiveTypingIndicator:(NSNotification *)notification
{
    NSLog(@"Typing Indicator BEGIN");
    NSString *convoID = [[notification.object valueForKey:@"identifier"] absoluteString];
    LYRTypingIndicator *typingIndicator = notification.userInfo[LYRTypingIndicatorObjectUserInfoKey];
    LYRIdentity *sender = typingIndicator.sender;
    NSMutableArray *participants = [NSMutableArray new]; 
    NSMutableDictionary *participantDict = [NSMutableDictionary new];  
    [participantDict setValue:[sender.avatarImageURL absoluteString] forKey:@"avatar_url"];
    [participantDict setValue:sender.displayName forKey:@"fullname"];
    [participantDict setValue:sender.userID forKey:@"id"];
    [participants addObject:[NSDictionary dictionaryWithDictionary:participantDict]];
    if (typingIndicator.action == LYRTypingIndicatorActionBegin) {
        NSLog(@"Typing Started");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"participant":participants,
                                                            @"event":@"LYRTypingDidBegin",
                                                            @"identifier":convoID}];
    }
    else if(typingIndicator==LYRTypingIndicatorActionPause){
        NSLog(@"Typing paused");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"participant":participants,
                                                            @"event":@"LYRTypingDidPause",
                                                            @"identifier":convoID}];
    }
    else {
        NSLog(@"Typing Stopped");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"participant":participants,
                                                            @"event":@"LYRTypingDidEnd",
                                                            @"identifier":convoID}];
    }
}

//#pragma mark - Layer Query Delegate
//- (void)queryController:(LYRQueryController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(LYRQueryControllerChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
//{
//  [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                               body:@{@"source":@"LayerQuery", @"type": @"queryControllerDidChangeObject"}];
//
//}
//- (void)queryControllerDidChangeContent:(LYRQueryController *)queryController
//{
//  [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                               body:@{@"source":@"LayerQuery", @"type": @"queryControllerDidChangeContent"}];
//
//}
//- (void)queryControllerWillChangeContent:(LYRQueryController *)queryController
//{
//  [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                                               body:@{@"source":@"LayerQuery", @"type": @"queryControllerWillChangeContent"}];
//
//}
#pragma mark - Fetching Layer Content

- (LYRConversation*)fetchLayerConversationWithParticipants:(NSArray*)participants andErr:(NSError*)convErr
{
    // Fetches all conversations between the authenticated user and the supplied participant
    // For more information about Querying, check out https://developer.layer.com/docs/integration/ios#querying
    
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    query.predicate = [LYRPredicate predicateWithProperty:@"participants" predicateOperator:LYRPredicateOperatorIsEqualTo value:participants];
    query.sortDescriptors = @[ [NSSortDescriptor sortDescriptorWithKey:@"createdAt" ascending:NO] ];
    
    NSOrderedSet *conversations = [_layerClient executeQuery:query error:&convErr];
    
    if (conversations.count <= 0) {
        NSError *conv_error = nil;
        return [_layerClient newConversationWithParticipants:[NSSet setWithArray: participants ] options:nil error:&conv_error];
    }
    else {
        return [conversations lastObject];
    }
}

-(id) fetchAllLayerConversasions
{
    // Fetches all LYRConversation objects
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
    
    NSError *error = nil;
    NSOrderedSet *conversations = [_layerClient executeQuery:query error:&error];
    if (conversations) {
        RCTLogInfo(@"%tu conversations", conversations.count);
    } else {
        RCTLogError(@"Query failed with error %@", error);
    }
    if (!error) {
        return conversations;
    }
    else {
        return error;
    }
}
- (void)setPresenceStatusAway
{
    if (_layerClient.isConnected) {
        NSError *errorStatus;
        BOOL success = [_layerClient setPresenceStatus:LYRIdentityPresenceStatusAway error:&errorStatus];
        if (!success) {
            NSLog(@"Failed to setPresenceStatus: %@", errorStatus);
        } else {
            NSLog(@"setPresenceStatus to Away");   
        }
    }
}
- (void)setPresenceStatusAvailable
{
    if (_layerClient.isConnected) {
        NSError *errorStatus;
        BOOL success = [_layerClient setPresenceStatus:LYRIdentityPresenceStatusAvailable error:&errorStatus];
        if (!success) {
            NSLog(@"Failed to setPresenceStatus: %@", errorStatus);
        } else {
            NSLog(@"setPresenceStatus to Available");   
        }
    }
}
@end
