//
//  JSONHelper.m
//  layerPod
//
//  Created by Joseph Johnson on 7/27/15.
//  Copyright (c) 2015 Facebook. All rights reserved.
/////////////////////////////////////////////////////////
/*
  This class will convert LYRConversation object properties
  to a JSON object that can be sent back to REACT in a callback

  Layer Objects need to be broken down into Dictionaries of simple classes
  (NSString, NSNumber, etc)
*/

#import "JSONHelper.h"

@implementation JSONHelper

#pragma mark-public methods
-(NSDictionary*)convertConvoToDictionary:(LYRConversation *)convo
{
  NSError *writeError = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[self convertCovoToDict:convo] options:NSJSONWritingPrettyPrinted error:&writeError];
  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  //NSLog(@"JSON Output: %@", jsonString);
  
  return [self convertCovoToDict:convo];
}

-(NSArray*)convertConvosToArray:(NSOrderedSet*)allConvos
{
  NSMutableArray *allArr = [NSMutableArray new];
  for(LYRConversation *convo in allConvos){
    [allArr addObject:[self convertCovoToDict:convo]];
  }
//  NSError *writeError = nil;
//  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:allArr options:NSJSONWritingPrettyPrinted error:&writeError];
//  NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//  NSLog(@"JSON Output: %@", jsonString);
  
  return allArr;
}

-(NSArray*)convertMessagesToArray:(NSOrderedSet *)allMessages
{
  NSMutableArray *allArr = [NSMutableArray new];
  for (LYRMessage *msg in allMessages) {
    [allArr addObject:[self convertMessageToDict:msg]];
  }
  return allArr;
}

-(NSDictionary*)convertErrorToDictionary:(NSError *)error
{
  return @{@"code":@(error.code),@"domain":error.domain,@"description":[error localizedDescription]};
}

-(NSArray*)convertChangeTypeUpdateToArray:(LYRObjectChange*)thisChange
{
  //NSLog(@"convertChangeTypeUpdateToArray: %@", thisChange);
  NSMutableArray *allChanges = [NSMutableArray new];
  id changeObject = thisChange.object;  
  NSMutableDictionary *changeData = [NSMutableDictionary new]; 
  [changeData setValue:NSStringFromClass([thisChange.object class]) forKey:@"object"];
  [changeData setValue:[[thisChange.object valueForKey:@"identifier"] absoluteString] forKey:@"identifier"];
  [changeData setValue:thisChange.property forKey:@"attribute"];
  [changeData setValue:@"LYRObjectChangeTypeUpdate" forKey:@"type"];
  if ([changeObject isKindOfClass:[LYRMessage class]]) {
    LYRMessage *message = changeObject;
    [changeData setValue:[[message.conversation valueForKey:@"identifier"] absoluteString] forKey:@"conversationIdentifier"];
  }   
  NSError *error;
  if (thisChange.afterValue){
    //NSLog(@"afterValue: %@", thisChange.afterValue);
    NSData *jsonDataAfter = [NSJSONSerialization dataWithJSONObject:thisChange.afterValue options:NSJSONWritingPrettyPrinted error:&error];
    //NSLog(@"afterValue: %@", jsonDataAfter);
    [changeData setValue:[[NSString alloc] initWithData:jsonDataAfter encoding:NSUTF8StringEncoding] forKey:@"changeTo"];
  } else {
    [changeData setValue:@"" forKey:@"changeTo"];  
  }
  if (thisChange.beforeValue){
    NSData *jsonDataBefore = [NSJSONSerialization dataWithJSONObject:thisChange.beforeValue options:NSJSONWritingPrettyPrinted error:&error];
    [changeData setValue:[[NSString alloc] initWithData:jsonDataBefore encoding:NSUTF8StringEncoding] forKey:@"changeFrom"];  
  } else {
    [changeData setValue:@"" forKey:@"changeFrom"]; 
  }
  [allChanges addObject:changeData];
  return allChanges;
}
-(NSArray*)convertChangeToArray:(LYRObjectChange*)thisChange
{
  //NSLog(@"Entro Changes %@", thisChange);
  NSMutableArray *allChanges = [NSMutableArray new];

  id changeObject = thisChange.object;  
  NSMutableDictionary *changeData = [NSMutableDictionary new];
  [changeData setValue:NSStringFromClass([thisChange.object class]) forKey:@"object"]; 

  //common properties
  if(thisChange.type==LYRObjectChangeTypeCreate)
    [changeData setValue:@"LYRObjectChangeTypeCreate" forKey:@"type"];
  else if(thisChange.type==LYRObjectChangeTypeDelete)
    [changeData setValue:@"LYRObjectChangeTypeDelete" forKey:@"type"];
  else if(thisChange.type==LYRObjectChangeTypeUpdate)
    [changeData setValue:@"LYRObjectChangeTypeUpdate" forKey:@"type"];
  [changeData setValue:thisChange.property forKey:@"attribute"];
  //TODO: make this safer in the event they change it from NSURL in the future
  [changeData setValue:[[thisChange.object valueForKey:@"identifier"] absoluteString] forKey:@"identifier"];

  if ([changeObject isKindOfClass:[LYRConversation class]]) {
    LYRConversation *conversation = changeObject;
    [changeData setValue:[self convertCovoToDict:conversation] forKey:@"conversation"];
    // Object is a conversation
  }

  if ([changeObject isKindOfClass:[LYRMessagePart class]]) {
    LYRMessagePart *messagePart = changeObject;
    //NSLog(@"changeObject: %@", changeObject);
    //NSLog(@"LYRMessagePart: %@", messagePart);
    [changeData setValue:[[self convertMessagePartToDict:messagePart] mutableCopy] forKey:@"part"];
    [allChanges addObject:changeData];
    return allChanges;
  }

  if ([changeObject isKindOfClass:[LYRMessage class]]) {
    LYRMessage *message = changeObject;
    [changeData setValue:[self convertMessageToDict:message] forKey:@"message"];
    [changeData setValue:[self convertConvoToDictionary:message.conversation] forKey:@"conversation"];
      // Object is a message
  }  

  if ([changeObject isKindOfClass:[LYRIdentity class]]) {
    LYRIdentity *participant = changeObject;
    [changeData setValue:participant.userID forKey:@"user"];
      // Object is a Identity
  }      
  //[changeData setValue:thisChange.property forKey:@"attribute"];

  //NSLog(@"PASO"); 
  //TODO: make this safer in the event they change it from NSURL in the future
  //[changeData setValue:[[thisChange.object valueForKey:@"identifier"] absoluteString] forKey:@"identifier"];

  if ([thisChange.afterValue isKindOfClass:[NSDate class]])
    [changeData setValue:[self convertDateToJSON:thisChange.afterValue] forKey:@"changeTo"];
  if ([thisChange.beforeValue isKindOfClass:[NSDate class]])
    [changeData setValue:[self convertDateToJSON:thisChange.beforeValue] forKey:@"changeFrom"];
  if ([thisChange.property isEqualToString:@"presenceStatus"]){
    if ([thisChange.afterValue isKindOfClass:[NSNumber class]]){
      [changeData setValue:[self converPresenceStatusIntToString:thisChange.afterValue] forKey:@"changeTo"];
    }
    if ([thisChange.beforeValue isKindOfClass:[NSNumber class]]){
      [changeData setValue:[self converPresenceStatusIntToString:thisChange.beforeValue] forKey:@"changeFrom"]; 
    }     
  }
  // if(thisChange.type==LYRObjectChangeTypeCreate)
  //   [changeData setValue:@"LYRObjectChangeTypeCreate" forKey:@"type"];
  // else if(thisChange.type==LYRObjectChangeTypeDelete)
  //   [changeData setValue:@"LYRObjectChangeTypeDelete" forKey:@"type"];
  // else if(thisChange.type==LYRObjectChangeTypeUpdate)
  //   [changeData setValue:@"LYRObjectChangeTypeUpdate" forKey:@"type"];

  [allChanges addObject:changeData];
  //NSLog(@"SALIO CHANGES: %@", allChanges);
  return allChanges;

}
-(NSArray*)convertChangesToArray:(NSArray*)changes
{
  //NSLog(@"Entro Changes %@", changes);
  NSMutableArray *allChanges = [NSMutableArray new];
  for(LYRObjectChange *thisChange in changes){
    id changeObject = thisChange.object;
    if ([changeObject isKindOfClass:[LYRMessage class]] || [changeObject isKindOfClass:[LYRConversation class]] || [changeObject isKindOfClass:[LYRIdentity class]]){
      
      NSMutableDictionary *changeData = [NSMutableDictionary new];
      [changeData setValue:NSStringFromClass([thisChange.object class]) forKey:@"object"];      
      
      if ([changeObject isKindOfClass:[LYRMessagePart class]]) {
        LYRMessagePart *messagePart = changeObject;
        //NSLog(@"LYRMessagePart: ", messagePart);
      }
      if ([changeObject isKindOfClass:[LYRConversation class]]) {
        LYRConversation *conversation = changeObject;
        [changeData setValue:[self convertCovoToDict:conversation] forKey:@"conversation"];
        // Object is a conversation
      }

      if ([changeObject isKindOfClass:[LYRMessage class]]) {
        LYRMessage *message = changeObject;
        [changeData setValue:[self convertMessageToDict:message] forKey:@"message"];
        [changeData setValue:[self convertConvoToDictionary:message.conversation] forKey:@"conversation"];
          // Object is a message
      }  
      if ([changeObject isKindOfClass:[LYRIdentity class]]) {
        LYRIdentity *participant = changeObject;
        [changeData setValue:participant.userID forKey:@"user"];
          // Object is a Identity
      }      
      [changeData setValue:thisChange.property forKey:@"attribute"];

      //NSLog(@"PASO"); 
      //TODO: make this safer in the event they change it from NSURL in the future
      [changeData setValue:[[thisChange.object valueForKey:@"identifier"] absoluteString] forKey:@"identifier"];
      //NSLog(@"afterValue: %@", thisChange.afterValue);
      //NSLog(@"Is of type: %@", [thisChange.afterValue class]);
      //NSCFNumber
      //NSNumber numberClass = [[NSNumber alloc] init];
      if ([thisChange.afterValue isKindOfClass:[NSDate class]])
        [changeData setValue:[self convertDateToJSON:thisChange.afterValue] forKey:@"changeTo"];
      if ([thisChange.beforeValue isKindOfClass:[NSDate class]])
        [changeData setValue:[self convertDateToJSON:thisChange.beforeValue] forKey:@"changeFrom"];
      if ([thisChange.property isEqualToString:@"presenceStatus"]){
        // NSString *presenceStatus;
        // LYRIdentityPresenceStatus status = thisChange.afterValue;
        // //NSLog(@"availabre %@: ", LYRIdentityPresenceStatusAvailable);
        // if (status == LYRIdentityPresenceStatusAvailable)
        //   presenceStatus = @"available";
        // if (status == LYRIdentityPresenceStatusAway)
        //   presenceStatus = @"away";
         // if ([thisChange.afterValue isKindOfClass:[NSNumber class]])
         //   [changeData setValue:thisChange.afterValue forKey:@"changeTo"];
         // if ([thisChange.beforeValue isKindOfClass:[NSNumber class]])
         //   [changeData setValue:thisChange.beforeValue forKey:@"changeFrom"];

        if ([thisChange.afterValue isKindOfClass:[NSNumber class]]){
          [changeData setValue:[self converPresenceStatusIntToString:thisChange.afterValue] forKey:@"changeTo"];
        }
        if ([thisChange.beforeValue isKindOfClass:[NSNumber class]]){
          [changeData setValue:[self converPresenceStatusIntToString:thisChange.beforeValue] forKey:@"changeFrom"]; 
        }     

      }
      //[changeData setValue:[thisChange.object description] forKey:@"description"];
      //if ([thisChange.beforeValue isKindOfClass:[LYRMessage class]]) {
        //NSLog(@"Entro if");
        
        //[changeData setValue:[[thisChange.beforeValue valueForKey:@"identifier"] absoluteString] forKey:@"change_from"];
        //[changeData setValue:[[thisChange.afterValue valueForKey:@"identifier"] absoluteString] forKey:@"change_to"];
       // [changeData setValue:thisChange.property forKey:@"attribute"];      
     // }
       // else {
          //if (thisChange.beforeValue)
          //  [changeData setObject:thisChange.beforeValue forKey:@"change_from"];
          //if (thisChange.afterValue)
          //  [changeData setObject:thisChange.afterValue forKey:@"change_to"];
        //[changeData setValue:thisChange.property forKey:@"attribute"];
     // }
      //NSLog(@"Salio if");
      if(thisChange.type==LYRObjectChangeTypeCreate)
        [changeData setValue:@"LYRObjectChangeTypeCreate" forKey:@"type"];
      else if(thisChange.type==LYRObjectChangeTypeDelete)
        [changeData setValue:@"LYRObjectChangeTypeDelete" forKey:@"type"];
      else if(thisChange.type==LYRObjectChangeTypeUpdate)
        [changeData setValue:@"LYRObjectChangeTypeUpdate" forKey:@"type"];

      [allChanges addObject:changeData];
      //NSLog(@"Salio Changes");
    }
  }
  //NSLog(@"allChanges: %@", allChanges);
  return allChanges;

}

#pragma mark-private methods
-(NSDictionary*)convertCovoToDict:(LYRConversation*)convo
{
  NSMutableDictionary *propertyDict = [NSMutableDictionary new];
  [propertyDict setValue:[convo.identifier absoluteString] forKey:@"identifier"];
  //[propertyDict setValue:@("2") forKey:@"hasUnreadMessages"];
  [propertyDict setValue:@(convo.totalNumberOfUnreadMessages) forKey:@"hasUnreadMessages"];
  [propertyDict setValue:@(convo.deliveryReceiptsEnabled) forKey:@"deliveryReceiptsEnabled"];
  [propertyDict setValue:@(convo.isDeleted) forKey:@"isDeleted"];
  NSString *title = [convo.metadata valueForKey:@"title"];
  [propertyDict setValue:title forKey:@"title"];
  [propertyDict setValue:convo.metadata forKey:@"metadata"];
  NSMutableArray *participants = [NSMutableArray new];
  
  for(LYRIdentity *participant in convo.participants){
      //NSLog(@"JSON Output participant: %@", participant);
     //[participants addObject:participant.userID];
     [participants addObject:[self convertParticipantToDict:participant]];
  }
  //[propertyDict setValue:[convo.participants allObjects] forKey:@"participants"];
  [propertyDict setValue:participants forKey:@"participants"];

  [propertyDict setValue:[self convertDateToJSON:convo.createdAt] forKey:@"createdAt"];
  [propertyDict setValue:[self convertMessageToDict:convo.lastMessage] forKey:@"lastMessage"];
  [propertyDict setValue:[NSMutableArray new] forKey:@"messages"];
  //[propertyDict setValue:@[@""] forKey:@"messages"];

  return [NSDictionary dictionaryWithDictionary:propertyDict];
}

-(NSDictionary*)convertMessageToDict:(LYRMessage*)msg
{
  NSMutableDictionary *propertyDict = [NSMutableDictionary new];
  [propertyDict setValue:[NSMutableDictionary dictionaryWithDictionary:msg.recipientStatusByUserID] forKey:@"recipientStatusByUserID"];
  [propertyDict setValue:@(msg.isSent) forKey:@"isSent"];
  [propertyDict setValue:@(msg.isDeleted) forKey:@"isDeleted"];
  [propertyDict setValue:@(msg.isUnread) forKey:@"isUnread"];
  [propertyDict setValue:msg.sender.userID forKey:@"sender"];
  [propertyDict setValue:@(msg.position) forKey:@"position"];
  [propertyDict setValue:[self convertParticipantToUser:msg.sender] forKey:@"user"];
  [propertyDict setValue:[self convertDateToJSON:msg.sentAt] forKey:@"sentAt"];
  [propertyDict setValue:[self convertDateToJSON:msg.receivedAt] forKey:@"receivedAt"];

  
  [propertyDict setValue:[msg.identifier absoluteString] forKey:@"identifier"];
  [propertyDict setValue:msg.recipientStatusByUserID forKey:@"recipientStatus"];
  NSMutableString *messageText= [NSMutableString new];
  NSMutableArray *messageParts = [NSMutableArray new];
  for(LYRMessagePart *part in msg.parts){
    [messageParts addObject:[self convertMessagePartToDict:part]];
    if([part.MIMEType isEqualToString:@"text/plain"]){
      [messageText appendString:[[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding]];
    }
    if([part.MIMEType isEqualToString:@"text/html"]){
      [messageText appendString:[[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding]];
    }
    if([part.MIMEType isEqualToString:@"image/jpg"] || [part.MIMEType isEqualToString:@"image/jpeg"] || [part.MIMEType isEqualToString:@"image/png"]){
      //[messageText appendString:[[NSString alloc] initWithData:part.data encoding:NSUTF8StringEncoding]];
      //[messageText appendString:@"*IMAGE*"];

      NSError *error;
      LYRProgress *progress = [part downloadContent:&error];
      if (error) {
          NSLog(@"Content failed download with error %@", error);
      }      
    }    
  }

  [propertyDict setValue:messageParts forKey:@"parts"];
  [propertyDict setValue:messageText forKey:@"text"];

  
  return [NSDictionary dictionaryWithDictionary:propertyDict];
}
-(NSString*)converPresenceStatusIntToString:(NSNumber*)presenceStatus
{
  if ([presenceStatus intValue] == 0)
    return @"offline";
  if ([presenceStatus intValue] == 1)
    return @"available";
  if ([presenceStatus intValue] == 2)
    return @"busy";
  if ([presenceStatus intValue] == 3)
    return @"away";
  if ([presenceStatus intValue] == 4)
    return @"invisible";  
  return @"offline";
}

-(NSString*)converPresenceStatusToString:(LYRIdentityPresenceStatus*)presenceStatus
{
  if (presenceStatus == LYRIdentityPresenceStatusOffline)
    return @"offline";
  if (presenceStatus == LYRIdentityPresenceStatusAvailable)
    return @"available";
  if (presenceStatus == LYRIdentityPresenceStatusBusy)
    return @"busy";
  if (presenceStatus == LYRIdentityPresenceStatusAway)
    return @"away";
  if (presenceStatus == LYRIdentityPresenceStatusInvisible)
    return @"invisible";  
  return @"offline";
}

-(NSDictionary*)convertParticipantToUser:(LYRIdentity*)participant
{
  NSMutableDictionary *participantDict = [NSMutableDictionary new];     
  [participantDict setValue:[self converPresenceStatusToString:participant.presenceStatus] forKey:@"status"];
  [participantDict setValue:[participant.avatarImageURL absoluteString] forKey:@"avatar"];
  [participantDict setValue:participant.displayName forKey:@"name"];
  [participantDict setValue:participant.userID forKey:@"_id"];

  return [NSDictionary dictionaryWithDictionary:participantDict];
}

-(NSDictionary*)convertParticipantToDict:(LYRIdentity*)participant
{
  //NSLog(@"participant: %@", participant);
  //NSLog(@"participant.presenceStatus: %@", participant.presenceStatus);
  NSMutableDictionary *participantDict = [NSMutableDictionary new]; 

  // if (participant.presenceStatus == LYRIdentityPresenceStatusOffline)
  //   [participantDict setValue:@"offline" forKey:@"status"];
  // if (participant.presenceStatus == LYRIdentityPresenceStatusAvailable)
  //   [participantDict setValue:@"available" forKey:@"status"];
  // if (participant.presenceStatus == LYRIdentityPresenceStatusBusy)
  //   [participantDict setValue:@"busy" forKey:@"status"];
  // if (participant.presenceStatus == LYRIdentityPresenceStatusAway)
  //   [participantDict setValue:@"away" forKey:@"status"];
  // if (participant.presenceStatus == LYRIdentityPresenceStatusInvisible)
  //   [participantDict setValue:@"invisible" forKey:@"status"];      
  [participantDict setValue:[self converPresenceStatusToString:participant.presenceStatus] forKey:@"status"];
  [participantDict setValue:[participant.avatarImageURL absoluteString] forKey:@"avatar_url"];
  [participantDict setValue:participant.displayName forKey:@"fullname"];
  [participantDict setValue:participant.userID forKey:@"id"];

  return [NSDictionary dictionaryWithDictionary:participantDict];
}

-(NSDictionary*)convertMessagePartToDict:(LYRMessagePart*)msgPart
{
  NSMutableDictionary *propertyDict = [NSMutableDictionary new];
  [propertyDict setValue:[msgPart.identifier absoluteString] forKey:@"identifier"];
  [propertyDict setValue:msgPart.MIMEType forKey:@"MIMEType"];
  [propertyDict setValue:@(msgPart.size) forKey:@"size"];
  [propertyDict setValue:@(msgPart.transferStatus) forKey:@"transferStatus"];
  //NSLog(@"****MESSAGEDATA %@", msgPart.data);
  if([msgPart.MIMEType isEqualToString:@"image/jpg"] || [msgPart.MIMEType isEqualToString:@"image/jpeg"] || [msgPart.MIMEType isEqualToString:@"image/png"]){
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    [formatter setDateFormat:@"yyyyMMdd'T'HHmmssSSSSSS"];
    NSString *stringDate = [formatter stringFromDate:[NSDate date]];
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSString *stringType = @"jpg";
    if([msgPart.MIMEType isEqualToString:@"image/jpeg"])
      stringType = @"jpeg";
    if([msgPart.MIMEType isEqualToString:@"image/png"])
      stringType = @"png";
    
    if (msgPart.data){
      NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:stringDate] URLByAppendingPathExtension:stringType];    
      //NSLog(@"fileURL: %@", [fileURL path]);  
      NSString *path = [fileURL path];
      NSData *data = msgPart.data;
      NSError *error = nil;
      [data writeToFile:path options:NSDataWritingAtomic error:&error];
      //NSLog(@"Write returned error: %@", [error localizedDescription]); 
      [propertyDict setValue:path forKey:@"data"];
    }

  } 
  if([msgPart.MIMEType isEqualToString:@"text/plain"]){
    [propertyDict setValue: [[NSString alloc] initWithData:msgPart.data encoding:NSUTF8StringEncoding] forKey:@"data"];
  }
  //NSLog(@"propertyDict: %@", propertyDict);
  return [NSDictionary dictionaryWithDictionary:propertyDict];
}

-(NSString*)convertDateToJSON:(NSDate*)date
{
  NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
  [fmt setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
  [fmt setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm'Z'"];
  return [fmt stringFromDate:date];
}
@end
