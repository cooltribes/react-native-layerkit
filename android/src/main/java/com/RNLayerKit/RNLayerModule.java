package com.RNLayerKit;


import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.uimanager.IllegalViewOperationException;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.bridge.ReactContext;

import com.layer.sdk.LayerClient;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.LayerObject;
import com.layer.sdk.messaging.Message;
import com.layer.sdk.messaging.MessageOptions;
import com.layer.sdk.messaging.MessagePart;
import com.layer.sdk.messaging.Metadata;
import com.layer.sdk.messaging.Identity;
import com.layer.sdk.messaging.Message.RecipientStatus;
import com.layer.sdk.messaging.PushNotificationPayload;
import com.layer.sdk.exceptions.LayerConversationException;

import java.util.List;
import java.util.Map;
import java.util.HashMap; 
import java.util.Set;
import java.util.ArrayList;
import java.util.Arrays;
import com.layer.sdk.query.Predicate;
import com.layer.sdk.query.Query;
import com.layer.sdk.query.Query.Builder;
import com.layer.sdk.query.SortDescriptor;
import com.layer.sdk.query.Queryable;

import java.util.Iterator;
import java.util.TimeZone;
import java.util.Objects;
import javax.annotation.Nullable;

import android.util.Log;
import java.lang.reflect.Type;
import java.text.SimpleDateFormat;
import java.text.DateFormat;

import java.nio.charset.Charset;


public class RNLayerModule extends ReactContextBaseJavaModule {

  ReactApplicationContext reactContext;
  private LayerClient layerClient;
  public RNLayerModule(ReactApplicationContext reactContext, LayerClient layerClient) {
    super(reactContext);
    this.reactContext = reactContext;
    this.layerClient = layerClient;
    
  }

  
  public static String userIDGlobal;
  public static String headerGlobal;
  public static Identity userIdentityGlobal;
  //public static final String DATE_FORMAT_NOW = "EEE, dd MMM yyyy HH:mm:ss Z";
  public static final String DATE_FORMAT_NOW = "yyyy-MM-dd'T'HH:mm'Z'";
  private static final Charset UTF8_CHARSET = Charset.forName("UTF-8");

  private MyAuthenticationListener authenticationListener;
  private MyChangeEventListener changeEventListener;
  @Override
  public String getName() {
    return "RNLayerKit";
  }

  public void sendEvent(ReactContext reactContext,
                         String eventName,
                         @Nullable WritableMap params) {
    reactContext
        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
        .emit(eventName, params);
  }

  @ReactMethod
  public void connect(
    String appIDstr,
    String deviceToken,
    Promise promise) {
    try {
      LayerClient.Options options = new LayerClient.Options();
      options.historicSyncPolicy(LayerClient.Options.HistoricSyncPolicy.ALL_MESSAGES);
      options.useFirebaseCloudMessaging(true);
      layerClient = LayerClient.newInstance(this.reactContext, appIDstr, options);

      if(authenticationListener == null)
        authenticationListener = new MyAuthenticationListener(this); 
      layerClient.registerAuthenticationListener(authenticationListener); 
      if(changeEventListener == null)
        changeEventListener = new MyChangeEventListener(this);       
      layerClient.registerEventListener(changeEventListener);      
      layerClient.connect();
      promise.resolve("YES");
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void disconnect(){
    if (layerClient != null)
      if (layerClient.isConnected())
        layerClient.deauthenticate();
  }


  @ReactMethod
  public void authenticateLayerWithUserID(
    String userID,
    String header,
    Promise promise) {
    try {
      WritableArray writableArray = new WritableNativeArray();
      userIDGlobal = userID;
      headerGlobal = header;
      layerClient.authenticate();
      String count;
      count = getMessagesCount(userID);
      writableArray.pushString("YES");
      writableArray.pushInt(Integer.parseInt(count));
      promise.resolve(writableArray);
      //userIdentityGlobal = layerClient.getAuthenticatedUser();
      //Log.v("User: ", userIdentityGlobal.toString() );
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  } 

  public String getMessagesCount(
    String userID){

    try {

      Query query = Query.builder(Message.class)
              .predicate(new Predicate(Message.Property.IS_UNREAD, Predicate
                .Operator.EQUAL_TO, true))
              // .predicate(new Predicate(Message.Property.SENDER_USER_ID, Predicate
              //   .Operator.NOT_EQUAL_TO, userID))              
              .build();

      List<Integer> results = layerClient.executeQuery(query, Query.ResultType.COUNT);
      if (results != null) 
        if (results.size() > 0)
        return String.valueOf(results.get(0));
      return "0";
    } catch (IllegalViewOperationException e) {
      return "0";
    }

  }

  @ReactMethod
  public void getConversations(
    int limit,
    int offset,
    Promise promise) {

    try {
      WritableArray writableArray = new WritableNativeArray();
      WritableArray writableArray2 = new WritableNativeArray();
      
      Builder builder = Query.builder(Conversation.class);
      if (limit != 0)
        builder.limit(limit);
      Query query = builder.build(); 
      // Query query = Query.builder(Conversation.class)
      //         .limit(10)
      //         .build();

      List<Conversation> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
      if (results != null) {
          writableArray.pushString("YES");
          writableArray.pushArray(conversationsToWritableArray(results));          
          promise.resolve(writableArray);
      }
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  } 

  @ReactMethod
  public void getMessages(
    String convoID,
    ReadableArray userIDs,
    int limit,
    int offset,
    Promise promise) {
    WritableArray writableArray = new WritableNativeArray();
    if (convoID != null){
      try {
        Builder builder = Query.builder(Message.class);
        builder.predicate(new Predicate(Message.Property.CONVERSATION, Predicate
                  .Operator.EQUAL_TO, this.fetchConvoWithId(convoID,layerClient)));
        if (limit != 0)
          builder.limit(limit);
        Query query = builder.build();
        List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
        if (results != null) {
          writableArray.pushString("YES");
          writableArray.pushArray(messagesToWritableArray(results));
          promise.resolve(writableArray);
        }
      } catch (IllegalViewOperationException e) {
        promise.reject(e);
      }
    } else {
      Conversation conversation = fetchLayerConversationWithParticipants(userIDs, layerClient);
      try {
        Builder builder = Query.builder(Message.class);
        builder.predicate(new Predicate(Message.Property.CONVERSATION, Predicate
                  .Operator.EQUAL_TO, conversation));
        if (limit != 0)
          builder.limit(limit);
        Query query = builder.build();
        List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
        if (results != null) {
          writableArray.pushString("YES");
          writableArray.pushArray(messagesToWritableArray(results));
          writableArray.pushString(conversation.getId().toString());
          promise.resolve(writableArray);
        }
      } catch (IllegalViewOperationException e) {
        promise.reject(e);
      }      
    }
  }
  @ReactMethod
  public void sendMessageToUserIDs(
    String messageText,
    ReadableArray userIDs,
    Promise promise) {
    try {
    if (!layerClient.isConnected()) {
      layerClient.connect();
    }      
      Conversation conversation = fetchLayerConversationWithParticipants(userIDs, layerClient);
      //Put the user's text into a message part, which has a MIME type of "text/plain" by default
      MessagePart messagePart = layerClient.newMessagePart(messageText);

      //Formats the push notification that the other participants will receive
      Map<String, String> data = new HashMap<String, String>();
      data.put("user_id", userIDGlobal);


      MessageOptions options = new MessageOptions();
      PushNotificationPayload payload = new PushNotificationPayload.Builder()
          .text(messageText)
          .title("New Message")
          .data(data)
          .build();
      options.defaultPushNotificationPayload(payload);      
      //TODO: Push Notifications
      //options.pushNotificationMessage(userIDGlobal + ": " + messageText);

      //Creates and returns a new message object with the given conversation and array of
      // message parts
      Message message = layerClient.newMessage(options, Arrays.asList(messagePart)); 

      conversation.send(message);
      promise.resolve("YES");
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    } 

  }

  private Conversation fetchLayerConversationWithParticipants(
    ReadableArray userIDs,
    LayerClient client
    ) {
    String[] userIDsArray = new String[userIDs.size()];
    for (int i = 0; i < userIDs.size(); i++) {
      userIDsArray[i] = userIDs.getString(i);  
    }
    Query query = Query.builder(Conversation.class)
    .predicate(new Predicate(Conversation.Property.PARTICIPANTS, Predicate.Operator.EQUAL_TO, userIDsArray))
    .build();

    List<Conversation> results = client.executeQuery(query, Query.ResultType.OBJECTS);
    if (results != null) {
      if (results.size() > 0){
        return results.get(0);
      }
    } 
    Conversation conversation;
    try {
       // Try creating a new distinct conversation with the given user
       conversation = layerClient.newConversationWithUserIds(userIDsArray);
    } catch (LayerConversationException e) {
       // If a distinct conversation with the given user already exists, use that one instead
       conversation = e.getConversation();
    }    
    return conversation;
  }

  private Conversation fetchConvoWithId(
    String convoID,
    LayerClient client
    ) {

    Query query = Query.builder(Conversation.class)
    .predicate(new Predicate(Conversation.Property.ID, Predicate.Operator.EQUAL_TO, convoID))
    .build();

    List<Conversation> results = client.executeQuery(query, Query.ResultType.OBJECTS);
    if (results != null) {
      if (results.size() > 0){
        return results.get(0);
      }
    }
    //TODO: Return null
    return null;
  }

  @Nullable
  public static WritableArray conversationsToWritableArray(List<Conversation> conversations) {
    WritableArray conversationsArray = new WritableNativeArray();

    if (conversations == null) {
        return null;
    }
    for(int i = 0; i < conversations.size(); i++ ){
      conversationsArray.pushMap(conversationToWritableMap(conversations.get(i)));
    }    

    return conversationsArray;

  }

  @Nullable
  public static WritableMap conversationToWritableMap(Conversation conversation) {
    WritableMap conversationMap = new WritableNativeMap();

    if (conversation == null) {
        return null;
    }
    DateFormat sdf = new SimpleDateFormat(DATE_FORMAT_NOW);
    TimeZone tz = TimeZone.getTimeZone("UTC");
    sdf.setTimeZone(tz);  
    conversationMap.putString("identifier", conversation.getId().toString());
    conversationMap.putBoolean("isDeleted", conversation.isDeleted());
    //TODO Put createdAt from MessagePart
    //conversationMap.putString("createdAt", conversation.createdAt.toString());
    conversationMap.putInt("hasUnreadMessages", conversation.getTotalUnreadMessageCount());
    conversationMap.putInt("totalNumberOfUnreadMessages", conversation.getTotalUnreadMessageCount());
    conversationMap.putMap("lastMessage", messageToWritableMap(conversation.getLastMessage()));
    //Log.v("RAFAgetMetadata", conversation.getMetadata().toString());
    conversationMap.putString("metadata", conversation.getMetadata().toString());
    //List<String> participants = conversation.getParticipants();
    Set<Identity> participants = conversation.getParticipants();
    WritableArray writableArray3 = new WritableNativeArray(); 
    for (Identity participant : participants) {    
    //for(int j = 0; j < participants.size(); j++ ){
      writableArray3.pushString(participant.getUserId());
    }

    conversationMap.putArray("participants", writableArray3);
    conversationMap.putBoolean("deliveryReceiptsEnabled", conversation.isDeliveryReceiptsEnabled());
    return conversationMap;

  }

  @Nullable
  public static WritableArray messagesToWritableArray(List<Message> messages) {
    WritableArray messagesArray = new WritableNativeArray();

    if (messages == null) {
        return null;
    }
    for(int i = 0; i < messages.size(); i++ ){
      messagesArray.pushMap(messageToWritableMap(messages.get(i)));
    }    

    return messagesArray;

  }

  @Nullable
  public static WritableMap messageToWritableMap(Message message) {
    WritableMap messageMap = new WritableNativeMap();

    if (message == null) {
        return null;
    }
    //Log.v("userIDGlobal", userIDGlobal);
    //Log.v("getUserId", message.getSender().getUserId().toString());
    //Log.v("message", message.toString());
    //if (!Objects.equals(userIDGlobal, message.getSender().getUserId().toString()))
    //  message.markAsRead();
    DateFormat sdf = new SimpleDateFormat(DATE_FORMAT_NOW);
    TimeZone tz = TimeZone.getTimeZone("UTC");
    sdf.setTimeZone(tz);  
    //Log.v("RAFAmessage", message.toString());  
    messageMap.putString("identifier",message.getId().toString());
    messageMap.putBoolean("isDeleted",message.isDeleted());
    messageMap.putBoolean("isSent",message.isSent());
    //TODO: FIX THIS
    //Log.v("userIdentityGlobal: ", userIdentityGlobal.toString());
    if (userIdentityGlobal != null){
      RecipientStatus recipientStatus = message.getRecipientStatus(userIdentityGlobal);
      messageMap.putString("Status",recipientStatus.toString());
    }
    
    //messageMap.putBoolean("isUnread",message.isUnread());
    if (message.getReceivedAt() != null)
      messageMap.putString("receivedAt",sdf.format(message.getReceivedAt()));
    if (message.getSentAt() != null)
      messageMap.putString("sentAt",sdf.format(message.getSentAt()));
    messageMap.putArray("part",messagePartsToWritableMap(message.getMessageParts()));
    messageMap.putString("sender",message.getSender().getUserId().toString()); 
    if (message.getMessageParts().get(0).getMimeType().equals("text/plain")){
      messageMap.putString("text",new String(message.getMessageParts().get(0).getData(), UTF8_CHARSET));
    } 
    return messageMap;

  }
  @Nullable
  public static WritableArray messagePartsToWritableMap(List<MessagePart> messageParts) {
    WritableArray messagePartArray = new WritableNativeArray();

    if (messageParts == null) {
        return null;
    }
    for(int i = 0; i < messageParts.size(); i++ ){
      messagePartArray.pushMap(messagePartToWritableMap(messageParts.get(i)));
    }
    
    return messagePartArray;
  }  
  @Nullable
  public static WritableMap messagePartToWritableMap(MessagePart messagePart) {
    WritableMap messagePartMap = new WritableNativeMap();

    if (messagePart == null) {
        return null;
    }

    messagePartMap.putString("identifier",messagePart.getId().toString());
    messagePartMap.putString("MIMEType",messagePart.getMimeType());
    //Log.v("RAFAgetMimeType", messagePart.getMimeType());
    if (messagePart.getMimeType().equals("text/plain")){
      String s = new String(messagePart.getData(), UTF8_CHARSET);
      //Log.v("RAFAString", s);
      messagePartMap.putString("data",s);
    }
    messagePartMap.putDouble("size",messagePart.getSize());
    messagePartMap.putInt("transferStatus",messagePart.getTransferStatus().getValue());
    
    return messagePartMap;
  }      


}
