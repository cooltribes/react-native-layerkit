#import <Foundation/Foundation.h>
#import <LayerKit/LayerKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface MessageParts : NSObject


/* converts LYRConversasion properties to a JSON object */
- (LYRMessagePart *)createMessagePartTextPlain:(NSString *)messageText;
- (LYRMessagePart *)createMessagePartImageJpg:(NSString *)messageText;
- (LYRMessagePart *)createMessagePartImagePng:(NSString *)messageText;

@end