#import "RNLayerKit.h"

@implementation RNLayerKit{
    NSString *_appID;
    LYRClient *_layerClient;
    JSONHelper *_jsonHelper;
    NSData *_deviceToken;
    NSString *_userID;
}

@synthesize bridge = _bridge;

- (id)init
{
    NSLog(@"LayerBridge not init");
    if ((self = [super init])) {
        NSLog(@"LayerBridge init");
        _jsonHelper = [JSONHelper new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:@"RNLayerKitNotification"
                                                   object:nil];
    }
    return self;
}

//- (dispatch_queue_t)methodQueue
//{
//  return dispatch_queue_create("com.schoolstatus.LayerCLientQueue", DISPATCH_QUEUE_SERIAL);
//}

RCT_EXPORT_MODULE()


RCT_EXPORT_METHOD(connect:(NSString*)appIDstr deviceToken:(NSData*)deviceToken                           
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject)
{
        NSURL *appID = [NSURL URLWithString:appIDstr];
        _deviceToken = deviceToken;
        if (!_layerClient) {
            NSLog(@"No Layer Client");     
            _layerClient = [LYRClient clientWithAppID:appID delegate:self options:nil];
        }   
        //[_layerClient setDelegate:self];
        if (!_layerClient.isConnected) {
            [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
                if (!success) {
                    NSLog(@"Failed to connect to Layer: %@", error);
                    RCTLogInfo(@"Failed to connect to Layer: %@", error);
                    reject(@"no_events", @"There were no events", error);
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
    static NSString *const MIMETypeTextPlain = @"text/plain";    
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
                conversationOptions.distinctByParticipants = YES;
                LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
                if (errorConversation && errorConversation.code == LYRErrorDistinctConversationExists) {
                    conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
                }

                NSError *error = nil;
                NSData *messageData = [messageText dataUsingEncoding:NSUTF8StringEncoding];
                LYRMessagePart *messagePart = [LYRMessagePart messagePartWithMIMEType:MIMETypeTextPlain data:messageData];

                // Creates and returns a new message object with the given conversation and array of message parts
                NSString *pushMessage= [NSString stringWithFormat:@"%@ says %@",_layerClient.authenticatedUser.userID ,messageText];
                
                LYRPushNotificationConfiguration *defaultConfiguration = [LYRPushNotificationConfiguration new];
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
                    id retErr = RCTMakeAndLogError(@"Error sending Layer message",error,NULL);
                    NSError *error = retErr;
                    reject(@"no_events", @"Error creating conversastion", error);        
                }
            }
        }];
    } else {
        NSError *errorConversation = nil;
        NSSet *participants = [NSSet setWithArray: userIDs];
        LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
        conversationOptions.distinctByParticipants = YES;
        LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
        if (errorConversation && errorConversation.code == LYRErrorDistinctConversationExists) {
            conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
        }

        NSError *error = nil;
        NSData *messageData = [messageText dataUsingEncoding:NSUTF8StringEncoding];
        LYRMessagePart *messagePart = [LYRMessagePart messagePartWithMIMEType:MIMETypeTextPlain data:messageData];

        // Creates and returns a new message object with the given conversation and array of message parts
        NSString *pushMessage= [NSString stringWithFormat:@"%@ says %@",_layerClient.authenticatedUser.userID ,messageText];
        
        LYRPushNotificationConfiguration *defaultConfiguration = [LYRPushNotificationConfiguration new];
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
            id retErr = RCTMakeAndLogError(@"Error sending Layer message",error,NULL);
            NSError *error = retErr;
            reject(@"no_events", @"Error creating conversastion", error);        
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
            resolve(@[thingToReturn,retData]); 
        }
    } else {
        NSError *errorConversation = nil;
        NSSet *participants = [NSSet setWithArray: userIDs];
        LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
        conversationOptions.distinctByParticipants = YES;
        LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
        NSLog(@"No conversation");
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
                resolve(@[thingToReturn,retData]); 
            }            
        }   
    }
}

RCT_EXPORT_METHOD(markAllAsRead:(NSString*)convoID callback:(RCTResponseSenderBlock)callback)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        [self sendErrorEvent:err];
    }
    else {
        NSError *error;
        BOOL success = [thisConvo markAllMessagesAsRead:&error];
        if(success){
            //RCTLogInfo(@"Layer Messages marked as read");
            callback(@[[NSNull null],@YES]);
        }
        else {
            id retErr = RCTMakeAndLogError(@"Error marking messages as read ",error,NULL);
            callback(@[retErr,[NSNull null]]);
        }
    }
    
}

RCT_EXPORT_METHOD(sendTypingBegin:(NSString*)convoID)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        [self sendErrorEvent:err];
    }
    else {
        [thisConvo sendTypingIndicator:LYRTypingIndicatorActionBegin];
    }
}

RCT_EXPORT_METHOD(sendTypingEnd:(NSString*)convoID)
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
        [self sendErrorEvent:err];
    }
    else {
        [thisConvo sendTypingIndicator:LYRTypingIndicatorActionBegin];
    }
}

RCT_EXPORT_METHOD(registerForTypingEvents)
{
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
            LayerQuery *query = [LayerQuery new];
            NSError *queryError;
            NSInteger count = [query fetchMessagesCount:userID client:_layerClient error:queryError];
            NSString *thingToReturn = @"YES";
            resolve(@[thingToReturn,[NSNumber numberWithInteger:count]]);            
        }
        else{
            id retErr = RCTMakeAndLogError(@"Error logging in",error,NULL);
            NSError *error = retErr;
            reject(@"no_events", @"TError logging in", error);            
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
            NSLog(@"Application did register for remote notifications");
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
    if (_layerClient.authenticatedUser)
        _userID = _layerClient.authenticatedUser.userID;
    LayerAuthenticate *lAuth = [LayerAuthenticate new];
    [lAuth authenticationChallenge:_userID layerClient:_layerClient nonce:nonce completion:^(NSError *error) {
        if (!error) {
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient", @"type": @"didReceiveAuthenticationChallengeWithNonce"}];           
        }
        else{
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"didReceiveAuthenticationChallengeWithNonce"}];            
        }
    }];    

}
- (void)layerClient:(LYRClient *)client objectsDidChange:(NSArray *)changes;
{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient",
                                                        @"type": @"objectsDidChange",
                                                        @"data":[_jsonHelper convertChangesToArray:changes]}];
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

#pragma mark - Typing Indicator
- (void)didReceiveTypingIndicator:(NSNotification *)notification
{
    //NSString *participantID = notification.userInfo[LYRTypingIndicatorParticipantUserInfoKey];
    NSString *convoID = [[notification.object valueForKey:@"identifier"] absoluteString];
    //LYRTypingIndicator typingIndicator = [notification.userInfo[LYRTypingIndicatorValueUserInfoKey] unsignedIntegerValue];
    NSString *participantID = notification.userInfo[LYRTypingIndicatorObjectUserInfoKey];
    LYRTypingIndicator *typingIndicator = notification.userInfo[LYRTypingIndicatorObjectUserInfoKey]; 

    if (typingIndicator == LYRTypingIndicatorActionBegin) {
        NSLog(@"Typing Started");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"data":@{@"participantID":participantID,
                                                                      @"event":@"LYRTypingDidBegin",
                                                                      @"conversationID":convoID}}];
    }
    else if(typingIndicator==LYRTypingIndicatorActionPause){
        NSLog(@"Typing paused");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"data":@{@"participantID":participantID,
                                                                      @"event":@"LYRTypingDidPause",
                                                                      @"conversationID":convoID}}];
    }
    else {
        NSLog(@"Typing Stopped");
        [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                     body:@{@"source":@"LayerClient",
                                                            @"type": @"typingIndicator",
                                                            @"data":@{@"participantID":participantID,
                                                                      @"event":@"LYRTypingDidEnd",
                                                                      @"conversationID":convoID}}];
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

@end
