#import <React/RCTBridgeModule.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTEventEmitter.h>
#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>
#import "JSONHelper.h"

@interface LayerConversation : RCTEventEmitter <RCTBridgeModule>

+(instancetype)conversationWithConvoID:(LYRClient *)layerClient bridge:(RCTBridge *)bridge convoID:(NSString*)convoID;
+(instancetype)conversationWithParticipants:(LYRClient *)layerClient bridge:(RCTBridge *)bridge userIDs:(NSArray*)userIDs;
-(NSUInteger)messagesAvailableLocally;
-(NSOrderedSet*)fetchMessages:(int)limit offset:(int)offset error:(NSError*)error;
@property (nonatomic, readonly) LYRConversation *conversation;
- (BOOL)removeParticipants:(NSArray*)userIDs error:(NSError*)error;
- (BOOL)addParticipants:(NSArray*)userIDs error:(NSError*)error;
- (BOOL)markAllMessagesAsRead;
//-(NSOrderedSet*)fetchConvosForClient:(LYRClient*)client limit:(int)limit offset:(int)offset error:(NSError*)error;
//-(NSInteger*)fetchMessagesCount:(NSString*)userID client:(LYRClient*)client error:(NSError*)error;
//-(LYRConversation*)fetchConvoWithId:(NSString*)convoID client:(LYRClient*)client error:(NSError*)error;
//-(NSOrderedSet*)fetchMessagesForConvoId:(NSString*)convoID client:(LYRClient*)client limit:(int)limit offset:(int)offset error:(NSError*)error;
@end
