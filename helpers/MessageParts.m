#import "MessageParts.h"

@implementation MessageParts

#pragma mark-public methods
- (LYRMessagePart *)createMessagePartTextPlain:(NSString *)messageText
{
  NSLog(@"messageText: %@", messageText);
  static NSString *const MIMETypeTextPlain = @"text/plain";
  NSData *messageData = [messageText dataUsingEncoding:NSUTF8StringEncoding];      
  return [LYRMessagePart messagePartWithMIMEType:MIMETypeTextPlain data:messageData];

}

- (LYRMessagePart *)createMessagePartImageJpg:(NSString *)messageText
//- (void)createMessagePartImageJpg:(NSString *)messageText toArray:(NSMutableArray*) arrayMessageParts
{
  static NSString *const MIMETypeImageJPG = @"image/jpg"; 

  //NSData* imageData = [[NSData alloc] init];
  __block NSData *imageDataReturn;
  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
  
  NSURL *url = [NSURL URLWithString:messageText];
  NSLog(@"url: %@", url);
  ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
  [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
      ALAssetRepresentation *rep = [asset defaultRepresentation];
      Byte *buffer = (Byte*)malloc(rep.size);
      NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
      NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
      NSLog(@"length : %lu", (unsigned long)data.length);
      UIImage *image =  [UIImage imageWithData:data];
      NSData *imageData = UIImageJPEGRepresentation(image,0.1);         
      imageDataReturn = imageData;
      dispatch_semaphore_signal(semaphore);

  } failureBlock:^(NSError *err) {
      NSLog(@"Error: %@",[err localizedDescription]);
      dispatch_semaphore_signal(semaphore);
  }];

  dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  NSLog(@"imageData: %@", imageDataReturn);
  return [LYRMessagePart messagePartWithMIMEType:MIMETypeImageJPG data:imageDataReturn];   
  // NSLog(@"messageText: %@", messageText);
  // NSURL *url = [NSURL URLWithString:messageText];
  
  // NSInputStream *fileStream = [NSInputStream inputStreamWithFileAtPath:url];
  // return [LYRMessagePart messagePartWithMIMEType:MIMETypeImageJPG stream:fileStream];

  //UIImage *image = [UIImage imageNamed:messageText];
  //NSURL *url = [NSURL URLWithString:messageText];
  //NSData *data = [NSData dataWithContentsOfURL:url];
  //UIImage *image = [[UIImage alloc] initWithData:data];


  // NSURL *url = [NSURL URLWithString:messageText];
  // ALAssetsLibrary *assetLibrary=[[ALAssetsLibrary alloc] init];
  // [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
  //     ALAssetRepresentation *rep = [asset defaultRepresentation];
  //     Byte *buffer = (Byte*)malloc(rep.size);
  //     NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:rep.size error:nil];
  //     NSData *data = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
  //     NSLog(@"length : %lu", (unsigned long)data.length);
  //     UIImage *image =  [UIImage imageWithData:data];
  //     NSData *imageData = UIImageJPEGRepresentation(image,0.1);         
  //     NSLog(@"imageData: %@", imageData);
  //     [arrayMessageParts addObject: [LYRMessagePart messagePartWithMIMEType:MIMETypeImageJPG data:imageData]];
  // } failureBlock:^(NSError *err) {
  //     NSLog(@"Error: %@",[err localizedDescription]);
  // }];


  

 
}

- (LYRMessagePart *)createMessagePartImagePng:(NSString *)messageText
{
  static NSString *const MIMETypeImagePNG = @"image/png";
  UIImage *image = [UIImage imageNamed:messageText];
  NSData *imageData = UIImagePNGRepresentation(image);      
  return [LYRMessagePart messagePartWithMIMEType:MIMETypeImagePNG data:imageData];  
}

@end