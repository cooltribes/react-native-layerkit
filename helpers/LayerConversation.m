#import "LayerConversation.h"

@interface LayerConversation ()
@property (nonatomic, readwrite) LYRConversation *conversation;
@property (nonatomic) BOOL shouldSynchronizeRemoteMessages;
@property (nonatomic, readwrite) LYRClient *layerClient;
@property (nonatomic, readwrite) int limit;
@property (nonatomic, readwrite) int offset;
@end

@implementation LayerConversation

+ (instancetype)conversationWithConvoID:(LYRClient *)layerClient bridge:(RCTBridge *)bridge convoID:(NSString*)convoID
{
    return [[self alloc] initWithLayerClient:layerClient bridge:bridge convoID:convoID];
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"LayerEvent"];
}

- (id)initWithLayerClient:(LYRClient *)layerClient bridge:(RCTBridge *)bridge convoID:(NSString*)convoID
{
    self = [super init];

    if (self) {
    	self.bridge = bridge;
    	NSError *error = nil;
  		LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRConversation class]];
  		query.predicate = [LYRPredicate predicateWithProperty:@"identifier" predicateOperator:LYRPredicateOperatorIsEqualTo value:convoID];
  		self.conversation = [[layerClient executeQuery:query error:&error] firstObject];  
  		_shouldSynchronizeRemoteMessages = YES;
  		_layerClient = layerClient;

    }
    return self;
}

- (NSUInteger)messagesAvailableLocally
{
    LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRMessage class]];
	query.predicate = [LYRPredicate predicateWithProperty:@"conversation" predicateOperator:LYRPredicateOperatorIsEqualTo value:self.conversation];
	query.resultType = LYRQueryResultTypeCount;
	NSError *error = nil;
	NSUInteger locallyMessageCount = [self.layerClient countForQuery:query error:&error];
    return locallyMessageCount;
}

-(NSOrderedSet*)fetchMessages:(int)limit offset:(int)offset error:(NSError*)error
{
	self.offset = offset;
	self.limit = limit;
	NSUInteger numberOfMessagesNeeded = MIN(self.conversation.totalNumberOfMessages, (offset + limit));
	if ([self messagesAvailableLocally] < numberOfMessagesNeeded ){
		[self requestToSynchronizeMoreMessages:numberOfMessagesNeeded sendEvent:true];
	} 

	LYRQuery *query = [LYRQuery queryWithQueryableClass:[LYRMessage class]];
  query.predicate = [LYRPredicate predicateWithProperty:@"conversation" predicateOperator:LYRPredicateOperatorIsEqualTo value:self.conversation];
  query.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"position" ascending:NO]];
  if(limit>0)
    query.limit=limit;
  query.offset=offset;  
  NSOrderedSet *messages = [self.layerClient executeQuery:query error:&error];
  numberOfMessagesNeeded = MIN(self.conversation.totalNumberOfMessages, (offset + limit + limit));
  NSLog(@"conversation totalShowMessages: %lu", numberOfMessagesNeeded);
  if ([self messagesAvailableLocally] < numberOfMessagesNeeded )
  	[self requestToSynchronizeMoreMessages:15 sendEvent:false];

  return messages;
}

- (void)requestToSynchronizeMoreMessages:(NSUInteger)numberOfMessagesToSynchronize sendEvent:(BOOL*)sendEvent
{
    if (!self.shouldSynchronizeRemoteMessages) {
        return;
    }
    
    self.shouldSynchronizeRemoteMessages = NO;
		if (sendEvent)
		[self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
                                         body:@{
                                         	@"source":@"LayerClient", 
                                         	@"type": @"SyncMessages",
                                         	@"status": @"init",
                                         	@"identifier":[self.conversation.identifier absoluteString]}];
    NSError *error;
    __weak BOOL weakSendEvent = sendEvent;
    NSLog(@"Entro en synchronizeMoreMessages");    
    __weak typeof(self) weakSelf = self;
    __block __weak id observer = [[NSNotificationCenter defaultCenter] addObserverForName:LYRConversationDidFinishSynchronizingNotification object:self.conversation queue:nil usingBlock:^(NSNotification * _Nonnull note) {
        if (observer) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }

        weakSelf.shouldSynchronizeRemoteMessages = YES;
        NSLog(@"Synchronizing Finish");
        NSLog(@"conversation messagesAvailableLocally: %lu", weakSelf.messagesAvailableLocally);
        NSLog(@"conversation messagesAvailableLocally: %lu", self.messagesAvailableLocally);
    		if (weakSendEvent){
    			NSError *error;
    			NSOrderedSet *convoMessages = [weakSelf fetchMessages:weakSelf.limit offset:weakSelf.offset error:error];
          JSONHelper *helper = [JSONHelper new];
          NSArray *retData = [helper convertMessagesToArray:convoMessages];    			
	    		[self.bridge.eventDispatcher sendAppEventWithName:@"LayerEvent"
	                                                 body:@{
	                                                 	@"source":@"LayerClient", 
					                                         	@"type": @"SyncMessages",
					                                         	@"status": @"finish",
					                                         	@"messages": retData,
					                                         	@"identifier":[weakSelf.conversation.identifier absoluteString]}];      
    		}
        //[weakSelf finishExpandingPaginationWindow];
    }];
    //self.messageCountBeforeSync = self.queryController.count;
    BOOL success = [self.conversation synchronizeMoreMessages:numberOfMessagesToSynchronize error:&error];
    if (!success) {
    		NSLog(@"Error Synchronizing: %@", error);
    		//id retErr = RCTMakeAndLogError(@"Error marking messages as read ",error,NULL);
        if (observer) {
            [[NSNotificationCenter defaultCenter] removeObserver:observer];
        }
        NSLog(@"conversation messagesAvailableLocally2: %lu", self.messagesAvailableLocally);
        //[weakSelf finishExpandingPaginationWindow];
        return;
    }
}


@end


