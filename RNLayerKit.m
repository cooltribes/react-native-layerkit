#import "RNLayerKit.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Crashlytics/Crashlytics.h>
NSData *_deviceToken;
LYRClient *_layerClient;
id _observer;

@interface RNLayerKit ()
//@property (nonatomic) LayerConversation *layerConversation;
//@property (nonatomic, readwrite) id observer;
@end

@implementation RNLayerKit{
    NSString *_appID;
    JSONHelper *_jsonHelper;
    MessageParts *_messageParts;
    //id _observer;
    //LayerConversation *_layerConversation;
    NSString *_userID;
    NSString *_header;
    NSString *_apiUrl;
    NSString *_conversationIdentifier;
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
    //NSLog(@"self.bridge 5 %@", self.bridge);
    if (self) {
         //NSLog(@"initWithLayerAppID self");
        _jsonHelper = [JSONHelper new];
        LYRClientOptions *clientOptions = [LYRClientOptions new];

        //clientOptions.synchronizationPolicy = 3;
        clientOptions.synchronizationPolicy = LYRClientSynchronizationPolicyPartialHistory;
        clientOptions.partialHistoryMessageCount = 1;
        _layerClient = [LYRClient clientWithAppID:layerAppID delegate:self options:clientOptions];
        //_layerClient.debuggingEnabled = YES;
        _messageParts = [MessageParts new];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:@"RNLayerKitNotification"
                                                   object:_layerClient];
        //[[NSNotificationCenter defaultCenter] removeObserver:self name:LYRClientObjectsDidChangeNotification object:nil]; 
        //NSLog(@"NSNotificationCenter");
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:LYRClientObjectsDidChangeNotification 
                                                                          object:nil 
                                                                           queue:nil 
                                                                      usingBlock:^(NSNotification * _Nonnull note) {
                                                                        [self layerClientObjectsDidChange:note];
                                                                      }];


        // [[NSNotificationCenter defaultCenter] addObserver:self
        //                                          selector:@selector(layerClientObjectsDidChange:)
        //                                              name:LYRClientObjectsDidChangeNotification
        //                                            object:nil];   
        //NSLog(@"NSNotificationCenter initWithLayerAppID %@", _observer);      
        // [[NSNotificationCenter defaultCenter] addObserver:self
        //                                          selector:@selector(willBeginSynchronizingNotification:)
        //                                              name:LYRConversationWillBeginSynchronizingNotification
        //                                            object:nil]; 



                                                           
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
   //NSLog(@"initialize Connecting");  
    if (!_layerClient.isConnected) {
        [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {

                NSLog(@"Failed to connect to Layer: %@", error);
                //RCTLogInfo(@"Failed to connect to Layer: %@", error);
                [self sendErrorEvent:error];
                reject(@"no_events", @"There were no events", error);
            } else {
                //NSLog(@"Connected to Layer!");
                RCTLogInfo(@"Connected to Layer!");
                if(_deviceToken)
                    [self updateRemoteNotificationDeviceToken:_deviceToken];
                NSString *thingToReturn = @"YES";
                resolve(thingToReturn);
            }
        }];
    } else {
        NSLog(@"Already Connected to Layer!");
        RCTLogInfo(@"Already Connected to Layer!");
        if(_deviceToken)
            [self updateRemoteNotificationDeviceToken:_deviceToken];
        NSString *thingToReturn = @"YES";
        resolve(thingToReturn);
    }
    
    
    
    
}
RCT_EXPORT_METHOD(refreshToken:(NSString *)deviceToken)
{
  NSLog(@"refreshToken: %@", deviceToken);
  [self updateRemoteNotificationDeviceToken:deviceToken];
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
    //NSLog(@"disconnect, entro");
    [_layerClient deauthenticateWithCompletion:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"disconnect, Failed to deauthenticate user: %@", error);
            [self sendErrorEvent:error];
        } else {
            NSLog(@"disconnect, User was deauthenticated");
            //[_layerClient disconnect];
        }
    }];
    
}
RCT_EXPORT_METHOD(selectConversation:(NSString *)convoID)
{
    self.layerConversation = [LayerConversation conversationWithConvoID:_layerClient bridge:(RCTBridge *)self.bridge convoID:convoID];
    
}

- (LYRConversation *)conversationWithParticipants:(NSSet *)participants
{
  NSError *errorConversation = nil;
  LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
  conversationOptions.distinctByParticipants = participants.count < 2;
  LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
  if (errorConversation){
    if  (errorConversation.code == LYRErrorDistinctConversationExists) {
        conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
        return conversation;
    } 
  } 
  return conversation;
}

- (LYRConversation *)conversationWithConvoID:(NSString *)convoID
{
    LayerQuery *query = [LayerQuery new];
    NSError *err;
    LYRConversation *conversation = [query fetchConvoWithId:convoID client:_layerClient error:err];
    if(err){
      NSLog(@"Error conversationWithConvoID %@ ",err);
    } 
    return conversation;


}
RCT_EXPORT_METHOD(clearChat)
{
  //NSLog(@"clearChat: %@", self.layerConversation);
  self.layerConversation = nil;
  //NSLog(@"clearChat: %@", self.layerConversation);
}

RCT_EXPORT_METHOD(deleteMessage:(NSString*)messageID 
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    NSError *errorQuery = nil;
    NSError *error = nil;
    LayerQuery *query = [LayerQuery new];
    LYRMessage *message = [query fetchMessageWithId:messageID client:_layerClient error:error];
    BOOL success = [message delete:LYRDeletionModeAllParticipants error:&error];
    if (success){
        resolve(@"YES"); 
    } else {
    NSError *errorMessage = error;
    NSLog(@"Error deleteMessage: %@", errorMessage);
    reject(@"no_events", @"Error deleteMessage", errorMessage);        
    }
}

RCT_EXPORT_METHOD(addParticipants:(NSString*)convoID userIDs:(NSString*)userIDs
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSError *error = nil;
  if ([self.layerConversation addParticipants:@[userIDs] error:error]){
    resolve(@"YES");    
  } else {
    id retErr = RCTMakeAndLogError(@"Error addParticipants",error,nil);
    NSError *errorMessage = retErr;        
    NSLog(@"Error addParticipants: %@", errorMessage);
    reject(@"no_events", @"Error addParticipants", errorMessage);   
  }

}

RCT_EXPORT_METHOD(removeParticipants:(NSString*)convoID userIDs:(NSString*)userIDs
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSError *error = nil;
  if ([self.layerConversation removeParticipants:@[userIDs] error:error]){
    resolve(@"YES");    
  } else {
    id retErr = RCTMakeAndLogError(@"Error removeParticipants",error,nil);
    NSError *errorMessage = retErr;        
    NSLog(@"Error removeParticipants: %@", errorMessage);
    reject(@"no_events", @"Error removeParticipants", errorMessage);   
  }

}

RCT_EXPORT_METHOD(newConversation:(NSArray*)userIDs
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  
  // NSSet *participants = [NSSet setWithArray: userIDs];
  // self.conversation = [self conversationWithParticipants:participants];  
  // if (self.conversation){
  //   resolve(@[@"YES",[self.conversation.identifier absoluteString]]);    
  // } else {
  //   NSLog(@"Error creating conversastion");
  //   reject(@"no_events", @"Error creating conversastion", nil);    
  // }
  self.layerConversation = [LayerConversation conversationWithParticipants:_layerClient bridge:(RCTBridge *)self.bridge userIDs:userIDs];
  //NSLog(@"newConversation conversation: %@", self.layerConversation);
  if (self.layerConversation.conversation){
    resolve(@[@"YES",[self.layerConversation.conversation.identifier absoluteString]]);    
  } else {
    NSLog(@"Error creating conversastion");
    reject(@"no_events", @"Error creating conversastion", nil);    
  }


}

// RCT_EXPORT_METHOD(sendMessageToConvoID:(NSArray*)parts convoID:(NSString*)convoID

//                   resolver:(RCTPromiseResolveBlock)resolve
//                   rejecter:(RCTPromiseRejectBlock)reject)
// {
//     if (@"ts")
//         resolve(@"YES");
//     else
//         reject(@"no_events", @"Error Sending Layer Message ", nil);
// }
RCT_EXPORT_METHOD(sendMessageToConvoID:(NSArray*)parts convoID:(NSString*)convoID
//RCT_EXPORT_METHOD(sendMessageToConvoID:(NSString*)messageText convoID:(NSString*)convoID
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{

    //NSLog(@"sendMessageToConvoID, Conversation 0: %@", self.layerConversation.conversation);
    if (!self.layerConversation.conversation)
      self.layerConversation = [LayerConversation conversationWithConvoID:_layerClient bridge:(RCTBridge *)self.bridge convoID:convoID];
    
    //NSLog(@"parts: %@", parts);
    MessageParts *messagePartsHelper = [MessageParts new];
    NSString *messageText = @"";
    NSMutableArray* arrayMessageParts = [[NSMutableArray alloc] init];
    for (NSDictionary *part in parts) {
      if ([@"text/plain" isEqualToString:part[@"type"]]){
        //NSLog(@"ENTRO PLAIN");
        messageText = part[@"message"];
        LYRMessagePart *messagePart = [messagePartsHelper createMessagePartTextPlain:messageText];
        [arrayMessageParts addObject: messagePart];
      }
      if ([@"image/jpg" isEqualToString:part[@"type"]] || [@"image/jpeg" isEqualToString:part[@"type"]]){
        //NSLog(@"ENTRO JPG");
        LYRMessagePart *messagePart = [messagePartsHelper createMessagePartImageJpg:part[@"message"]];
        //NSLog(@"********MESSAGE PARTS: %@", messagePart);
        [arrayMessageParts addObject: messagePart];
      }    
      if ([@"image/png" isEqualToString:part[@"type"]]){
        //NSLog(@"ENTRO JPG");
        LYRMessagePart *messagePart = [messagePartsHelper createMessagePartImagePng:part[@"message"]];
        //NSLog(@"********MESSAGE PARTS: %@", messagePart);
        [arrayMessageParts addObject: messagePart];
      }         
    }
    //NSLog(@"*******SALIO IF********** %@", arrayMessageParts);
    
    //if (![convoID isEqualToString:[self.conversation.identifier absoluteString]])
    //  self.conversation = [self conversationWithConvoID:convoID];
    
    NSError *error = nil;

    // Creates and returns a new message object with the given conversation and array of message parts
    NSString *pushMessage= [NSString stringWithFormat:@"%@", messageText];
    LYRPushNotificationConfiguration *defaultConfiguration = [LYRPushNotificationConfiguration new];
    defaultConfiguration.title = [[_layerClient authenticatedUser] displayName];
    defaultConfiguration.alert = pushMessage;
    defaultConfiguration.category = @"category_lqs";
    defaultConfiguration.sound = @"layerbell.caf";
    
    LYRMessageOptions *messageOptions = [LYRMessageOptions new];
    messageOptions.pushNotificationConfiguration = defaultConfiguration;
    
    //LYRMessagePart *messagePart = [self createMessagePartTextPlain:messageText];
    //LYRMessage *message = [_layerClient newMessageWithParts:@[messagePart] options:messageOptions error:nil];
    LYRMessage *message = [_layerClient newMessageWithParts:arrayMessageParts options:messageOptions error:nil];
    // Sends the specified message
    // NSLog(@"sendMessageToConvoID, authenticatedUser %@", arrayMessageParts);
    // NSLog(@"sendMessageToConvoID, authenticatedUser %@", [[_layerClient authenticatedUser] displayName]);
    // NSLog(@"sendMessageToConvoID, getConversationIdentifier %@", [self getConversationIdentifier]);
    // NSLog(@"sendMessageToConvoID _layerClient.isConnected %d", _layerClient.isConnected);
    
    // NSLog(@"sendMessageToConvoID, Conversation 2: %@", self.layerConversation.conversation);
    // NSLog(@"sendMessageToConvoID, Message: %@", message);

    BOOL success = [self.layerConversation.conversation sendMessage:message error:&error];
    
    if(success){
      //NSLog(@"sendMessageToConvoID, Layer Message sent to %@", convoID);
      RCTLogInfo(@"sendMessageToConvoID, Layer Message sent to %@", convoID);
      resolve(@"YES");
    }
    else {
      //NSLog(@"sendMessageToConvoID, Error Sending Layer Message %@", error);
      RCTLogInfo(@"Error Sending Layer Message",error);      
      NSLog(@"Error Sending Layer Message %@", error);
      [self sendErrorEvent:error];
      reject(@"no_events", @"Error Sending Layer Message ", error);
      
    }      
   
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
        //NSLog(@"ENTRO not isConnected");
        [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            if (!success) {
                NSLog(@"Failed to connect to Layer: %@", error);
                RCTLogInfo(@"Failed to connect to Layer: %@", error);
                [self sendErrorEvent:error];
                reject(@"no_events", @"There were no events", error);
            } else {
                NSError *errorConversation = nil;
                NSSet *participants = [NSSet setWithArray: userIDs];
                LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
                
                if ([userIDs count] >= 3)
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
                    [self sendErrorEvent:error];
                    reject(@"no_events", @"Error creating conversastion", nil);
                }
            }
        }];
    } else {
       // NSLog("isConnected");
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
            [self sendErrorEvent:error];
            reject(@"no_events", @"Error creating conversastion", nil);
        }
    }
    
}
typedef void (^ SuccessBlock)(BOOL success);
typedef void (^ FailureBlock)(NSError *error, NSInteger statusCode);
- (void)myFunction:(LYRClient*)layerClient  success:(SuccessBlock)success failure:(FailureBlock)failure{
    if (layerClient.isConnected) {
        //NSLog(@"Layer is connected, block");
        success(TRUE);
    } else {
        //NSLog(@"Layer is not connected, block");
        [_layerClient connectWithCompletion:^(BOOL success, NSError *error) {
            // if (success){
            //     success(TRUE);
            // }
            // else{
            //     NSLog(@"Failed to connect to Layer: %@", error);
            //     failure(error, 0);
            // }
            if (!success){
                [self sendErrorEvent:error];
                NSLog(@"Failed to connect to Layer: %@", error);
            }

        }];
        success(YES);
        
    }
    
}
RCT_EXPORT_METHOD(getConversations:(int)limit offset:(int)offset
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
   // for (LYRSession *session in _layerClient.sessions) {
   //  NSLog(@"Session authenticatedUser %@", session.authenticatedUser.userID);
   // }
   //NSLog(@"Authentication currentSession.state getConversations: %lu", _layerClient.currentSession.state);
   //NSLog(@"getConversations layerConversation: %@", self.layerConversation);
   [self myFunction:_layerClient  success:^(BOOL success) {
       if(success){
        //NSLog(@"Entro en el block");
        //NSLog(@"Conversation layerConversation getConversations: %@", self.layerConversation);
        LayerQuery *query = [LayerQuery new];
        NSError *queryError;
        id allConvos = [query fetchConvosForClient:_layerClient limit:limit offset:offset error:queryError];
        if(queryError){
          id retErr = RCTMakeAndLogError(@"Error getting Layer conversations",queryError,NULL);
          NSError *error = retErr;
          [self sendErrorEvent:error];
          reject(@"no_events", @"Error creating conversastion", error);
        }
        else{
          JSONHelper *helper = [JSONHelper new];
          NSArray *retData = [helper convertConvosToArray:allConvos];
          NSString *thingToReturn = @"YES";
          resolve(@[thingToReturn,retData]);
        }
       }
    } failure:^(NSError *error, NSInteger statusCode) {
        NSLog(@"Error Error");
    }]; 

}

RCT_EXPORT_METHOD(setConversationTitle:(NSString*)convoID title:(NSString*)title
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
      //self.conversation = [self conversationWithConvoID:convoID];    
    if (![convoID isEqualToString:[self.layerConversation.conversation.identifier absoluteString]])
      self.layerConversation = [LayerConversation conversationWithConvoID:_layerClient bridge:(RCTBridge *)self.bridge convoID:convoID];        
    if (self.layerConversation.conversation){
      [self.layerConversation.conversation setValue:title forMetadataAtKeyPath:@"title"];
      resolve(@"YES");
    } else {
      reject(@"no_events", @"Error setting metadata", nil);
    }

    
}
RCT_EXPORT_METHOD(syncMessages:(NSString*)convoID userIDs:(NSArray*)userIDs limit:(int)limit                  
                resolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject)
{
    // if (![convoID isEqualToString:[self.conversation.identifier absoluteString]])
    //   self.conversation = [self conversationWithConvoID:convoID];
    // if (self.conversation){
    //     NSError *error;
    //     [self.conversation synchronizeMoreMessages:limit error:&error]; 
    //     if (error){
    //         reject(@"no_events", @"Error synchronizeMoreMessages", error);
    //     } else {
    //         NSString *thingToReturn = @"YES";
    //         resolve(@[thingToReturn]);
    //     }
    // } 
            NSString *thingToReturn = @"YES";
            resolve(@[thingToReturn]);        
}
RCT_EXPORT_METHOD(getMessages:(NSString*)convoID userIDs:(NSArray*)userIDs limit:(int)limit offset:(int)offset
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (convoID){
        if (![convoID isEqualToString:[self.layerConversation.conversation.identifier absoluteString]])
          self.layerConversation = [LayerConversation conversationWithConvoID:_layerClient bridge:(RCTBridge *)self.bridge convoID:convoID];
        // NSLog(@"Conversation layerConversation getMessages: %@", self.layerConversation);
        // NSLog(@"Conversation totalNumberOfMessages: %lu", self.layerConversation.conversation.totalNumberOfMessages);
        // NSLog(@"conversation messagesAvailableLocally: %lu", self.layerConversation.messagesAvailableLocally);
        //self.conversation = [self conversationWithConvoID:convoID];
        _conversationIdentifier = [self getConversationIdentifier];
        self.conversation = self.layerConversation.conversation;
        //UPDATE LASTPOSITION
        [self.conversation setValue:[NSString stringWithFormat:@"%ld",self.conversation.lastMessage.position] forMetadataAtKeyPath:@"lastPosition"];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerClientObjectsDidChange:) name:LYRClientObjectsDidChangeNotification object:nil];
       
        //LayerQuery *query = [LayerQuery new];
        NSError *queryError;
        //NSOrderedSet *convoMessages = [query fetchMessagesForConvoId:convoID client:_layerClient limit:limit offset:offset error:queryError];
        NSOrderedSet *convoMessages = [self.layerConversation fetchMessages:limit offset:offset error:queryError];
        if(queryError){
            id retErr = RCTMakeAndLogError(@"Error getting Layer messages",queryError,NULL);
            NSError *error = retErr;
            [self sendErrorEvent:error];
            reject(@"no_events", @"Error creating conversastion", error);
            
        }
        else{
            JSONHelper *helper = [JSONHelper new];
            NSArray *retData = [helper convertMessagesToArray:convoMessages];
            NSString *thingToReturn = @"YES";
            [self.layerConversation markAllMessagesAsRead];
            LayerQuery *query = [LayerQuery new];
            NSError *queryError;
            NSInteger count = [query fetchUnReadMessagesCount:_layerClient error:queryError];
            NSLog(@"fetchUnReadMessagesCount: %lu",count);

            // if (![convoID isEqualToString:[self.conversation.identifier absoluteString]])
            //   self.conversation = [self conversationWithConvoID:convoID];
            // if (self.conversation){
            //     NSError *error;
            //     [self.conversation synchronizeMoreMessages:15 error:&error]; 
            // }   
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
            
            //NSLog(@"NSNotificationCenter getMessages %@", _observer); 
            if (_observer) {
                //NSLog(@"NSNotificationCenter removeObserver");
                [[NSNotificationCenter defaultCenter] removeObserver:_observer];
            } 
           
            _observer = [[NSNotificationCenter defaultCenter] addObserverForName:LYRClientObjectsDidChangeNotification 
                                                                              object:nil 
                                                                               queue:nil 
                                                                          usingBlock:^(NSNotification * _Nonnull note) {
                                                                            [self layerClientObjectsDidChange:note];
                                                                          }];            
            // self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:LYRConversationWillBeginSynchronizingNotification 
            //                                                                   object:nil 
            //                                                                 selector:@selector(layerClientObjectsDidChange:)];                       
            //[[NSNotificationCenter defaultCenter] removeObserver:self name:LYRClientObjectsDidChangeNotification object:nil];
            // [[NSNotificationCenter defaultCenter] addObserver:self
            //                                          selector:@selector(layerClientObjectsDidChange:)
            //                                              name:LYRClientObjectsDidChangeNotification
            //                                             object:nil];           
            resolve(@[thingToReturn,retData]);
        }
    } else {
        NSError *errorConversation = nil;
        //NSLog(@"userIDs: %@", userIDs);
        NSSet *participants = [NSSet setWithArray: userIDs];
        LYRConversationOptions *conversationOptions = [LYRConversationOptions new];
        if ([userIDs count] >= 2)
            conversationOptions.distinctByParticipants = NO;
        else
            conversationOptions.distinctByParticipants = YES;
        LYRConversation *conversation = [_layerClient newConversationWithParticipants:participants options:conversationOptions error:&errorConversation];
        //NSLog(@"No conversation");
        //NSLog(@"errorConversation %@", errorConversation);
        if (errorConversation && errorConversation.code == LYRErrorDistinctConversationExists) {
            conversation = errorConversation.userInfo[LYRExistingDistinctConversationKey];
           // NSLog(@"old conversation");
        }
        if (conversation){
            LayerQuery *query = [LayerQuery new];
            NSError *queryError;
            //NSLog(@"old conversation get messages %@", conversation);
            NSOrderedSet *convoMessages = [query fetchMessagesForConvoId:conversation client:_layerClient limit:limit offset:offset error:queryError];
            if(queryError){
                id retErr = RCTMakeAndLogError(@"Error getting Layer messages",queryError,NULL);
                NSError *error = retErr;
                [self sendErrorEvent:error];
                reject(@"no_events", @"Error creating conversastion", error);
                
            }
            else{
                JSONHelper *helper = [JSONHelper new];
                NSArray *retData = [helper convertMessagesToArray:convoMessages];
                NSString *thingToReturn = @"YES";
                //[self.conversation synchronizeMoreMessages:numberOfMessagesToSynchronize error:&error];
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
            NSInteger count = [query fetchMessagesCount:convoID client:_layerClient error:queryError];
            resolve(@[[NSNumber numberWithInteger:count],@YES]);
        }
        else {
            if (thisConvo != NULL) {
                id retErr = RCTMakeAndLogError(@"Error marking messages as read ",error,NULL);
                NSError *error = retErr;
                [self sendErrorEvent:error];
                reject(@"no_events", @"Error mark all as read", error);
            }
        }
    }
    
    
}
RCT_EXPORT_METHOD(sendTypingBegin:(NSString*)convoID)
{
 
  //NSLog(@"sendTypingBegin %@ and %@", convoID, [self.layerConversation.conversation.identifier absoluteString]);
  if (![convoID isEqualToString:[self.layerConversation.conversation.identifier absoluteString]])
    self.layerConversation = [LayerConversation conversationWithConvoID:_layerClient bridge:(RCTBridge *)self.bridge convoID:convoID];        
  if (self.layerConversation.conversation)
    [self.layerConversation.conversation sendTypingIndicator:LYRTypingIndicatorActionBegin];  
}

RCT_EXPORT_METHOD(sendTypingEnd:(NSString*)convoID)
{
  //NSLog(@"sendTypingEnd %@ and %@", convoID, [self.layerConversation.conversation.identifier absoluteString]);
  if (![convoID isEqualToString:[self.layerConversation.conversation.identifier absoluteString]])
    self.layerConversation = [LayerConversation conversationWithConvoID:_layerClient bridge:(RCTBridge *)self.bridge convoID:convoID];        
  if (self.layerConversation.conversation)
    [self.layerConversation.conversation sendTypingIndicator:LYRTypingIndicatorActionFinish];   
}

// RCT_EXPORT_METHOD(sendTypingBegin:(NSString*)convoID
//                 resolver:(RCTPromiseResolveBlock)resolve
//                 rejecter:(RCTPromiseRejectBlock)reject)
// {
//     LayerQuery *query = [LayerQuery new];
//     NSError *err;
//     LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
//     if(err){
//         id retErr = RCTMakeAndLogError(@"Error getting conversation on sendTypingBegin ",err,NULL);
//         NSError *error = retErr;
//         reject(@"no_events", @"Error getting conversation on sendTypingBegin", error);
//     }
//     else {
//         [thisConvo sendTypingIndicator:LYRTypingIndicatorActionBegin];
//         NSLog(@"LYRTypingIndicatorActionBegin");
//         NSString *thingToReturn = @"YES";
//         resolve(thingToReturn);
//     }
// }

// RCT_EXPORT_METHOD(sendTypingEnd:(NSString*)convoID 
//                 resolver:(RCTPromiseResolveBlock)resolve
//                 rejecter:(RCTPromiseRejectBlock)reject)
// {
//     LayerQuery *query = [LayerQuery new];
//     NSError *err;
//     LYRConversation *thisConvo = [query fetchConvoWithId:convoID client:_layerClient error:err];
//     if(err){
//         id retErr = RCTMakeAndLogError(@"Error getting conversation on sendTypingEnd ",err,NULL);
//         NSError *error = retErr;
//         reject(@"no_events", @"Error getting conversation on sendTypingEnd", error);
//     }
//     else {
//         [thisConvo sendTypingIndicator:LYRTypingIndicatorActionFinish];
//         NSLog(@"LYRTypingIndicatorActionFinish");
//         NSString *thingToReturn = @"YES";
//         resolve(thingToReturn);
//     }
// }

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
    [self sendLogEvent:[NSString stringWithFormat:@"Start Authentication state: %lu", _layerClient.currentSession.state]];
    
    // if (!_layerClient.isConnected) {
    //     NSLog(@"authenticateLayerWithUserID, Layer is not connected");
    // } else {
    //     NSLog(@"authenticateLayerWithUserID, Layer is connected");
    // }
    _userID = userID;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LYRConversationDidReceiveTypingIndicatorNotification object:nil];    
      LayerAuthenticate *lAuth = [LayerAuthenticate new];
      //NSLog(@"authenticateLayerWithUserID, Layer authenticating");
      [lAuth authenticateLayerWithUserID:userID header:header layerClient:_layerClient completion:^(NSError *error) {
          if (!error) {
              [self sendLogEvent:[NSString stringWithFormat:@"Successfully Authenticated state: %lu", _layerClient.currentSession.state]];

              //NSLog(@"authenticateLayerWithUserID, Layer authenticated");
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
                 // NSLog(@"authenticateLayerWithUserID, Failed to setPresenceStatus: %@", errorStatus);
                  [self sendErrorEvent:errorStatus];
                  // handle error here
              } else {
                  NSLog(@"authenticateLayerWithUserID, setPresenceStatus to Available"); 
              }           
              resolve(@[thingToReturn,[NSNumber numberWithInteger:count]]);
          }
          else{
              RCTLogError(@"authenticateLayerWithUserID, Error logging in %@",error);
              //NSError *error = retErr;
              [self sendErrorEvent:error];
              reject(@"no_events", @"Error logging in", error);
          }
      }];
    
}
- (NSString*) getConversationIdentifier
{
    return [self.layerConversation.conversation.identifier absoluteString];
}






// - (void) willBeginSynchronizingNotification:(LYRConversation *) conversation
// {
//   NSLog(@"Entro willBeginSynchronizingNotification %@", conversation);
//     // [notification name] should always be @"TestNotification"
//     // unless you use this method for observation of other notifications
//     // as well.
//     //NSLog (@"Enter to receivedNotification!");
//     // if ([[notification name] isEqualToString:@"RNLayerKitNotification"])
//     // {
//     //     //NSLog (@"Successfully received the test notification!");
//     //     NSDictionary *userInfo = notification.userInfo;
//     //     NSData *myToken = [userInfo objectForKey:@"deviceToken"];
//     //     [self updateRemoteNotificationDeviceToken:myToken];
//     // }
// }

#pragma mark - Register for Push Notif
- (void) receivedNotification:(NSNotification *) notification
{
    // [notification name] should always be @"TestNotification"
    // unless you use this method for observation of other notifications
    // as well.
    //NSLog (@"Enter to receivedNotification!");
    if ([[notification name] isEqualToString:@"RNLayerKitNotification"])
    {
        //NSLog (@"Successfully received the test notification!");
        NSDictionary *userInfo = notification.userInfo;
        NSData *myToken = [userInfo objectForKey:@"deviceToken"];
        [self updateRemoteNotificationDeviceToken:myToken];
    }
}
-(void)updateRemoteNotificationDeviceToken:(NSData*)deviceToken
{
    // if we haven't initialize our client, then save the token for later
    //NSLog (@"Enter on updateRemoteNotificationDeviceToken %@", deviceToken);
    if(!_layerClient){
        _deviceToken=deviceToken;
    }
    else{
        NSError *error;
        BOOL success = [_layerClient updateRemoteNotificationDeviceToken:deviceToken error:&error];
        if (success) {
            //NSLog(@"Application did register for remote notifications: %@", deviceToken);
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                         body:@{@"source":@"LayerClient",@"type": @"didRegisterForRemoteNotificationsWithDeviceToken"}];
        } else {
            NSLog(@"Error updating Layer device token for push:%@", error);
            [self sendErrorEvent:error];
        }
    }
    
}
#pragma mark - Error Handle
-(void)sendErrorEvent:(NSError*)error{
    [[Crashlytics sharedInstance] recordError:error];
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"error",@"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]}}];
}
-(void)sendLogEvent:(NSString*)description{
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", @"type": @"log",@"description":description}];
}
#pragma mark - Layer Client Delegate
- (void)layerClient:(LYRClient *)client didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"PUSH ERROR: %@", error);
}
- (void)layerClient:(LYRClient *)client didAuthenticateNotification:(NSString *)notification
{
    
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient",@"type": @"didAuthenticateNotification", @"data":@{@"notification":notification}}];
}
- (void)layerClient:(LYRClient *)client didDeauthenticateNotification:(NSString *)notification
{
    
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient",@"type": @"didDeauthenticateNotification", @"data":@{@"notification":notification}}];
}
- (void)layerClient:(LYRClient *)client didAuthenticateAsUserID:(NSString *)userID
{
    
    //NSLog(@"didAuthenticateAsUserID %@", userID);
    //NSLog(@"self.bridge.eventDispatcher %@", self.bridge.eventDispatcher);
    //NSLog(@"self.bridge %@", self.bridge);
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
   // NSLog(@"****didFinishContentTransfer: %@",contentTransferType);
    // if (contentTransferType == LYRContentTransferTypeUpload)
    //     NSLog(@"UPLOAD");
    // if (contentTransferType == LYRContentTransferTypeUpload)
    //     NSLog(@"UPLOAD");    
    //NSLog(@"****Object: %@",object);
    JSONHelper *helper = [JSONHelper new];
    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                                 body:@{@"source":@"LayerClient", 
                                                 @"type": @"didFinishContentTransfer",
                                                @"data":[_jsonHelper convertMessagePartToDict:object]}];
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
    //NSLog(@"Layer Client did receive an authentication challenge with nonce=%@", nonce);
   // NSLog(@"Header: %@",_header);
    if (_layerClient.authenticatedUser)
        _userID = _layerClient.authenticatedUser.userID;
   // NSLog(@"LayerUserID: %@",_userID);
    //if (_header){
        LayerAuthenticate *lAuth = [LayerAuthenticate new];
        [lAuth authenticationChallenge:_userID layerClient:_layerClient nonce:nonce header:_header apiUrl:_apiUrl completion:^(NSError *error) {
        //[lAuth authenticationChallenge:_userID layerClient:_layerClient nonce:nonce header:_header apiUrl:@"ff" completion:^(NSError *error) {
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
                                                             body:@{@"source":@"LayerClient", 
                                                             @"type": @"didFailAuthenticationChallengeWithNonce",
                                                             @"error":@{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]} }];
            }
        }];
    //}
    
}
// - (void)layerClientObjectsDidChange:(NSNotification *)notification
// {
//     NSArray *changes = notification.userInfo[LYRClientObjectChangesUserInfoKey];
//     NSLog(@"Conversation layerConversation userInfo: %@", notification.userInfo);
//     NSLog(@"Conversation layerConversation _conversationIdentifier: %@", _conversationIdentifier);
//     NSLog(@"Conversation layerConversation _userID: %@", _userID);
//     NSLog(@"Conversation layerConversation _header: %@", _header);
//     NSLog(@"Conversation layerConversation _apiUrl: %@", _apiUrl);

//     for(LYRObjectChange *thisChange in changes){
//         id changeObject = thisChange.object;
//         if ([changeObject isKindOfClass:[LYRMessage class]] || [changeObject isKindOfClass:[LYRConversation class]] || [changeObject isKindOfClass:[LYRIdentity class]]){
//             if ([changeObject isKindOfClass:[LYRMessage class]]){
//                 LYRMessage *message = changeObject;
//                 NSLog(@"Conversation layerConversation objectsDidChange2: %@", [self getConversationIdentifier]);
//                 NSLog(@"self.conversation layerConversation: %@", _conversationIdentifier);
//                 NSLog(@"selfConversation identifier: %@",[self.layerConversation.conversation.identifier absoluteString]);
//                 NSLog(@"eventConversation: %@",[message.conversation.identifier absoluteString]);
//                 NSLog(@"Conversation totalNumberOfMessages: %lu", self.layerConversation.conversation.totalNumberOfMessages);
//                 if ([[self.layerConversation.conversation.identifier absoluteString] isEqualToString:[message.conversation.identifier absoluteString]]){
//                     [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                          body:@{@"source":@"LayerClient",
//                                 @"type": @"objectsDidChange",
//                                 @"data":[_jsonHelper convertChangeToArray:thisChange]}];                    
//               rando q  }
//             } else {
//                 [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
//                      body:@{@"source":@"LayerClient",
//                             @"type": @"objectsDidChange",
//                             @"data":[_jsonHelper convertChangeToArray:thisChange]}];
//             }
//         }
//     }     
// }

//- (void)layerClient:(LYRClient *)client objectsDidChange:(NSArray *)changes
- (void)layerClientObjectsDidChange:(NSNotification *)notification
//- (void)layerClient:(LYRClient *)client objectsDidChange:(NSNotification *)notification
{
    //NSLog(@"self.layerConversation %@", self.layerConversation);
    //NSLog(@"_conversationIdentifier: %@", _conversationIdentifier);
    //NSLog(@"notification: %@", notification);
    //NSLog(@"layerClient: %@", _layerClient);
    //NSLog(@"self.bridge: %@", self.bridge);
    if (!notification.object) return;
    if (![notification.object isEqual:_layerClient]) return;
    if (!_jsonHelper)
        _jsonHelper = [JSONHelper new];
    
    NSArray *changes = notification.userInfo[LYRClientObjectChangesUserInfoKey];    

    //NSLog(@"Conversation layerConversation objectsDidChange: %@", self.layerConversation);
    NSInteger *countBadge = 0;
    for(LYRObjectChange *thisChange in changes){
      //NSLog(@"objectsDidChange: %@",thisChange);



        id changeObject = thisChange.object;
        // if ([changeObject isKindOfClass:[LYRMessage class]] && thisChange.type == LYRObjectChangeTypeCreate) {
        //   LYRMessage *message = changeObject;
        //   //NSLog(@"message.position: %lu", message.position);
        //   //NSLog(@"message.conversation.lastMessage.position: %lu", message.conversation.lastMessage.position);
        //   //[changeData setValue:[self convertMessageToDict:message] forKey:@"message"];
        //   //[changeData setValue:[self convertConvoToDictionary:message.conversation] forKey:@"conversation"];
        //     // Object is a message
        // }     

        if ([changeObject isKindOfClass:[LYRMessagePart class]]){
            //NSLog(@"thisChange: %@", thisChange);
            LYRMessagePart *messagePart = changeObject;
            if (messagePart.transferStatus == LYRContentTransferComplete)
              if (self.layerConversation){
                LYRMessage *message = messagePart.message;
                if (self.layerConversation.conversation.identifier == message.conversation.identifier){              
                [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                     body:@{@"source":@"LayerClient",
                            @"type": @"objectsDidChange",
                            @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                            @"data":[_jsonHelper convertChangeToArray:thisChange]}];   
                }
              }       
        }

        if ([changeObject isKindOfClass:[LYRMessage class]]){
         //NSLog(@"layerClientObjectsDidChange LYRMessage %@", thisChange);
          if(thisChange.type==LYRObjectChangeTypeUpdate && [thisChange.property isEqualToString:@"recipientStatusByUserID"]){
            //TODO || message.conversation.participants.size <= 2
            if (self.layerConversation){
              LYRMessage *message = changeObject;
              if (self.layerConversation.conversation.identifier == message.conversation.identifier){  
                [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                     body:@{@"source":@"LayerClient",
                            @"type": @"objectsDidChange",
                            @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                            @"data":[_jsonHelper convertChangeTypeUpdateToArray:thisChange]}]; 
              }
            }
          }           
          //if([thisChange.property isEqualToString:@"isSent"] || [thisChange.property isEqualToString:@"isDeleted"])
          if(thisChange.type==LYRObjectChangeTypeDelete)
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                 body:@{@"source":@"LayerClient",
                        @"type": @"objectsDidChange",
                        @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                        @"data":[_jsonHelper convertChangeToArray:thisChange]}];
          
          if(thisChange.type==LYRObjectChangeTypeCreate){
            LYRMessage *message = changeObject;
            LYRConversation *conversation = message.conversation;
            //NSLog(@"LYRMessage LYRObjectChangeTypeCreate: %@", thisChange);
            NSString *lastPosition = [conversation.metadata valueForKey:@"lastPosition"];
            if (lastPosition){
              if (([lastPosition compare:[NSString stringWithFormat:@"%ld",message.position]] != NSOrderedDescending) ){                
                if (self.layerConversation)
                  if (self.layerConversation.conversation.identifier == conversation.identifier){ 
                    //NSLog(@"message.position %@", [NSString stringWithFormat:@"%ld",message.position]);
                    //NSLog(@"lastPosition %@", lastPosition);                                
                    [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                         body:@{@"source":@"LayerClient",
                                @"type": @"objectsDidChange",
                                @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                                @"data":[_jsonHelper convertChangeToArray:thisChange]}]; 
                  }    
              }  
            } 
            //NSLog(@"lastPosition: %@", lastPosition);
            //NSLog(@"message.position: %ld", message.position);
          }
        }

        if ([changeObject isKindOfClass:[LYRIdentity class]]){
          //NSLog(@"layerClientObjectsDidChange LYRIdentity");
          if ([thisChange.property isEqualToString:@"presenceStatus"]){
                [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                     body:@{@"source":@"LayerClient",
                            @"type": @"objectsDidChange",
                            @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                            @"data":[_jsonHelper convertChangeToArray:thisChange]}];  
          }      
        }    

        if ([changeObject isKindOfClass:[LYRConversation class]]){ 
         // NSLog(@"layerClientObjectsDidChange LYRConversation");             
          
          if ([thisChange.property isEqualToString:@"totalNumberOfUnreadMessages"]){
            LayerQuery *query = [LayerQuery new];
            NSError *queryError;
            //NSLog(@"ENTRO");
            countBadge = [query fetchUnReadMessagesCount:_layerClient error:queryError];
            //NSLog(@"ENTRO %ld", countBadge);
          }
          // if ([thisChange.property isEqualToString:@"hasUnreadMessages"])
          //   NSLog(@"hasUnreadMessages");
          // IF lastMessage metadata totalNumberOfUnreadMessages participants
           
          if( thisChange.type==LYRObjectChangeTypeUpdate && [thisChange.property isEqualToString:@"lastMessage"]){            
            LYRConversation *conversation = changeObject;
            LYRMessage *message = conversation.lastMessage;
            //NSLog(@"message.position: %ld", message.position);
            NSString *lastPosition = [conversation.metadata valueForKey:@"lastPosition"];
           if (([lastPosition compare:[NSString stringWithFormat:@"%ld",message.position]] != NSOrderedDescending) ){  
              [conversation setValue:[NSString stringWithFormat:@"%ld",message.position] forMetadataAtKeyPath:@"lastPosition"];              
              [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                 body:@{@"source":@"LayerClient",
                        @"type": @"objectsDidChange",
                        @"data":[_jsonHelper convertChangeToArray:thisChange]}];
            }
            if (self.layerConversation){
              if (self.layerConversation.conversation.identifier == conversation.identifier){                
                [message markAsRead:nil];
              }
            }
            //NSLog(@"self.bridge: %@", self.bridge);
            //NSLog(@"countBadge: %ld", countBadge);
            //[self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent" body:@""];

            // [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
            //    body:@{@"source":@"LayerClient",
            //           @"type": @"objectsDidChange",
            //           @"data":[_jsonHelper convertChangeToArray:thisChange]}];

          }
          //NSLog(@"ayerClientObjectsDidChange LYRConversation %@", _jsonHelper);
          if( thisChange.type==LYRObjectChangeTypeUpdate && [thisChange.property isEqualToString:@"metadata"]){
            //NSLog(@"metadata change: %@", thisChange);
            NSDictionary *changeTo = thisChange.afterValue;
            NSDictionary *changeFrom = thisChange.beforeValue;
            // NSLog(@"changeTo: %@", changeTo);
            // NSLog(@"changeTo title: %@", changeTo[@"title"]);
            // NSLog(@"changeFrom: %@", changeFrom);
            // NSLog(@"changeFrom title: %@", changeFrom[@"title"]);
            if (changeTo[@"title"]){
              if (![changeTo[@"title"] isEqualToString:changeFrom[@"title"]])
                [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                     body:@{@"source":@"LayerClient",
                            @"type": @"objectsDidChange",
                            @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                            @"data":[_jsonHelper convertChangeToArray:thisChange]}];
            }
            //LYRConversation *conversation = changeObject;
            //NSString *changeFrom = [conversation.metadata valueForKey:@"lastPosition"];
            //NSString *changeTo = [conversation.metadata valueForKey:@"lastPosition"];
            
            
          }
          if( thisChange.type==LYRObjectChangeTypeUpdate && 
              ([thisChange.property isEqualToString:@"totalNumberOfUnreadMessages"] ||
                [thisChange.property isEqualToString:@"participants"]) )
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                 body:@{@"source":@"LayerClient",
                        @"type": @"objectsDidChange",
                        @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                        @"data":[_jsonHelper convertChangeToArray:thisChange]}]; 
          else if( thisChange.type==LYRObjectChangeTypeCreate )
            [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                 body:@{@"source":@"LayerClient",
                        @"type": @"objectsDidChange",
                        @"badge":[NSString stringWithFormat:@"%ld", (long)countBadge ],
                        @"data":[_jsonHelper convertChangeToArray:thisChange]}];

        }
        //NSLog(@"SALIO");


            // if ([changeObject isKindOfClass:[LYRMessage class]]){
            //     LYRMessage *message = changeObject;
            //     NSLog(@"Conversation layerConversation objectsDidChange2: %@", [self getConversationIdentifier]);
            //     NSLog(@"self.conversation layerConversation: %@",[self.conversation.identifier absoluteString]);
            //     NSLog(@"selfConversation identifier: %@",[self.layerConversation.conversation.identifier absoluteString]);
            //     NSLog(@"eventConversation: %@",[message.conversation.identifier absoluteString]);
            //     NSLog(@"Conversation totalNumberOfMessages: %lu", self.layerConversation.conversation.totalNumberOfMessages);
            //     if ([[self.layerConversation.conversation.identifier absoluteString] isEqualToString:[message.conversation.identifier absoluteString]]){
            //         [self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
            //              body:@{@"source":@"LayerClient",
            //                     @"type": @"objectsDidChange",
            //                     @"data":[_jsonHelper convertChangeToArray:thisChange]}];                    
            //     }
            // } else {

            //}
        
    }


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
    NSLog(@"Layer Did Disconnect");
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
