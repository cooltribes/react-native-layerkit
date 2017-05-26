package com.RNLayerKit.react;


import android.util.Log;

import com.RNLayerKit.listeners.AuthenticationListener;
import com.RNLayerKit.listeners.ChangeEventListener;
import com.RNLayerKit.listeners.IndicatorListener;
import com.RNLayerKit.listeners.ConnectionListener;

import com.layer.sdk.listeners.LayerTypingIndicatorListener;
import com.RNLayerKit.singleton.LayerkitSingleton;
import com.RNLayerKit.utils.ConverterHelper;
import com.RNLayerKit.utils.LayerUtils;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.facebook.react.uimanager.IllegalViewOperationException;
import com.layer.sdk.LayerClient;
import com.layer.sdk.exceptions.LayerConversationException;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.Identity;
import com.layer.sdk.messaging.Message;
import com.layer.sdk.messaging.MessageOptions;
import com.layer.sdk.messaging.MessagePart;
import com.layer.sdk.messaging.PushNotificationPayload;
import com.layer.sdk.query.Predicate;
import com.layer.sdk.query.Query;
import com.layer.sdk.query.Query.Builder;
import com.layer.sdk.messaging.Presence;

import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Nullable;


public class RNLayerModule extends ReactContextBaseJavaModule {

    private final static String TAG = RNLayerModule.class.getSimpleName();

    // Class Variables
    private final static String YES = "YES";
    private final static String ZERO = "0";

    // Class intaces
    private ReactApplicationContext reactContext;
    private LayerClient layerClient;

    private AuthenticationListener authenticationListener;
    private ChangeEventListener changeEventListener;
    private IndicatorListener layerTypingIndicatorListener;
    private ConnectionListener connectionListener;

    @SuppressWarnings("WeakerAccess")
    public RNLayerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    /* ***************************************************************************** */
    /*                                                                               */
    /* OVERRIDE METHODS                                                              */
    /*                                                                               */
    /* ***************************************************************************** */

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

    /* ***************************************************************************** */
    /*                                                                               */
    /* REACT METHODS                                                                 */
    /*                                                                               */
    /* ***************************************************************************** */

    @ReactMethod
    @SuppressWarnings("unused")
    public void sendTypingBegin(String convoID, Promise promise) {
        try {

            Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();

            if(!conversation.getId().toString().equals(convoID) || conversation == null ) {                 
                conversation = fetchConvoWithId(convoID, layerClient);
            }         
            
            if (conversation != null) {                
                conversation.send(LayerTypingIndicatorListener.TypingIndicator.STARTED);
                promise.resolve( YES );                
            } else  {
                Log.v(TAG, "Error getting conversation from convo id");
                promise.reject( new Throwable("Error getting conversation") );
            }
        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }
    }
    @ReactMethod
    @SuppressWarnings("unused")
    public void sendTypingEnd(String convoID, Promise promise) {
        try {

            Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();

            if(!conversation.getId().toString().equals(convoID) || conversation == null ) {                 
                conversation = fetchConvoWithId(convoID, layerClient);
            }   
            
            if (conversation != null) {               
                conversation.send(LayerTypingIndicatorListener.TypingIndicator.FINISHED);
                promise.resolve( YES );
                
            } else  {
                Log.v(TAG, "Error getting conversation from convo id");
                promise.reject( new Throwable("Error getting conversation") );
            }
        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }
    }

    @ReactMethod
    @SuppressWarnings("unused")
    public void connect(
            String appIDstr,
            String deviceToken,
            Promise promise) {

        try {
            LayerClient.Options options = new LayerClient.Options();
            options.historicSyncPolicy(LayerClient.Options.HistoricSyncPolicy.ALL_MESSAGES);
            options.useFirebaseCloudMessaging(true);
            layerClient = LayerClient.newInstance(this.reactContext, appIDstr, options);

            LayerUtils.setAppId(this.reactContext, appIDstr);

            if (connectionListener == null) {
                connectionListener = new ConnectionListener(this, layerClient);
            }
            layerClient.registerConnectionListener(connectionListener);

            if (authenticationListener == null) {
                authenticationListener = new AuthenticationListener();
            }
            layerClient.registerAuthenticationListener(authenticationListener);

            if (changeEventListener == null) {
                changeEventListener = new ChangeEventListener( this );
            }
            layerClient.registerEventListener(changeEventListener);

            if (layerTypingIndicatorListener == null) {
                layerTypingIndicatorListener = new IndicatorListener( this, layerClient );
            }
            layerTypingIndicatorListener.onResume();

            layerClient.connect();

            promise.resolve( YES );

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }

    @ReactMethod
    @SuppressWarnings("unused")
    public void disconnect() {

        if (layerClient != null) {
            if (layerClient.isConnected()) {              
                layerClient.deauthenticate();
                layerClient.disconnect();                
                layerClient.unregisterConnectionListener(connectionListener);
            }
        }

    }


    @ReactMethod
    @SuppressWarnings("unused")
    public void authenticateLayerWithUserID(
            String userID,
            String header,
            Promise promise) {

        try {

            LayerkitSingleton.getInstance().setUserIdGlobal(userID);
            LayerkitSingleton.getInstance().setHeaderGlobal(header);

            if(!layerClient.isAuthenticated())
                layerClient.authenticate();

            if(layerClient.isAuthenticated())
              layerClient.setPresenceStatus(Presence.PresenceStatus.AVAILABLE);

            String count;
            count = getMessagesCount();

            WritableArray writableArray = new WritableNativeArray();
            writableArray.pushString(YES);
            writableArray.pushInt(Integer.parseInt(count));

            promise.resolve(writableArray);
        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }

    @SuppressWarnings("unchecked")
    private String getMessagesCount() {

        try {

            Query query = Query.builder(Message.class)
                    .predicate(new Predicate(Message.Property.IS_UNREAD, Predicate
                            .Operator.EQUAL_TO, true))
                    .build();

            List results = layerClient.executeQuery(query, Query.ResultType.COUNT);

            if (results != null && results.size() > 0) {
                return String.valueOf(results.get(0));
            }

        } catch (IllegalViewOperationException ignored) {
        }

        return ZERO;

    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "UnusedParameters", "unused"})
    public void getConversations(
            int limit,
            int offset,
            Promise promise) {

        try {
            WritableArray writableArray = new WritableNativeArray();

            Builder builder = Query.builder(Conversation.class);

            if (limit != 0) {
                builder.limit(limit);
            }

            Query query = builder.build();

            List results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);

            if (results != null) {
                writableArray.pushString(YES);
                writableArray.pushArray(ConverterHelper.conversationsToWritableArray(results));
                promise.resolve(writableArray);
            } else {
                Log.v(TAG, "Error get conversations");
                promise.reject( new Throwable("Error get conversations") );
            }

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "unused"})
    public void markAllAsRead (
            String convoID,
            Promise promise) {

        try {
            Builder builder = Query.builder(Message.class);

            Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();

            if(!conversation.getId().toString().equals(convoID) || conversation == null ) {               
                conversation = fetchConvoWithId(convoID, layerClient);
            }            

            if (conversation != null) {

                builder.predicate(new Predicate(Message.Property.CONVERSATION, Predicate
                        .Operator.EQUAL_TO, conversation));

                Query query = builder.build();

                List messages = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
                if (messages != null) {

                    for (int i = 0; i < messages.size(); i++) {
                        Message message = (Message) messages.get(i);
                        Identity sender = message.getSender();
                        if (sender != null && !sender.getUserId().equals(LayerkitSingleton.getInstance().getUserIdGlobal())) {
                            message.markAsRead();
                        }
                    }

                    WritableArray writableArray = new WritableNativeArray();
                    String count = getMessagesCount();
                    writableArray.pushInt(Integer.parseInt(count));
                    writableArray.pushString(YES);
                    promise.resolve(writableArray);

                } else {
                    Log.v(TAG, "Error getting conversations");
                    promise.reject(new Throwable("Error getting conversations"));
                }

            } else  {
                Log.v(TAG, "Error getting conversation from convo id");
                promise.reject(new Throwable("Error getting conversation from convo id"));
            }
        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }
    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "UnusedParameters", "unused"})
    public void getMessages(
            String convoID,
            ReadableArray userIDs,
            int limit,
            int offset,
            Promise promise) {

        WritableArray writableArray = new WritableNativeArray();

        if (convoID != null) {
            try {

                Conversation conversation = fetchConvoWithId(convoID, layerClient);

                if (conversation != null) {
                    LayerkitSingleton.getInstance().setConversationGlobal(conversation);            //// set conversation global
                }

                Builder builder = Query.builder(Message.class);
                builder.predicate(new Predicate(Message.Property.CONVERSATION, Predicate
                        .Operator.EQUAL_TO, conversation));
                if (limit != 0) {
                    builder.limit(limit);
                }
                Query query = builder.build();
                List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
                if (results != null) {
                    writableArray.pushString(YES);
                    writableArray.pushArray(ConverterHelper.messagesToWritableArray(results));
                    promise.resolve(writableArray);
                }
            } catch (IllegalViewOperationException e) {
                promise.reject(e);
            }
        } else {
            Conversation conversation = fetchLayerConversationWithParticipants(userIDs, layerClient);
            if (conversation != null) {
                LayerkitSingleton.getInstance().setConversationGlobal(conversation);            //// set conversation global
            }
            try {
                Builder builder = Query.builder(Message.class);
                builder.predicate(new Predicate(Message.Property.CONVERSATION, Predicate
                        .Operator.EQUAL_TO, conversation));
                if (limit != 0)
                    builder.limit(limit);
                Query query = builder.build();
                List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
                if (results != null) {
                    writableArray.pushString(YES);
                    writableArray.pushArray(ConverterHelper.messagesToWritableArray(results));
                    writableArray.pushString(conversation.getId().toString());
                    promise.resolve(writableArray);
                }
            } catch (IllegalViewOperationException e) {
                promise.reject(e);
            }
        }
    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "unused"})
    public void newConversation(            
            ReadableArray userIDs,
            Promise promise) {

        try {
            WritableArray writableArray = new WritableNativeArray();

            if (!layerClient.isConnected()) {
                layerClient.connect();
            }

            Conversation conversation = fetchLayerConversationWithParticipants(userIDs, layerClient);
            LayerkitSingleton.getInstance().setConversationGlobal(conversation);                     //// set conversation global

            writableArray.pushString(YES);
            writableArray.pushString(conversation.getId().toString());  
            promise.resolve(writableArray);

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }
    @ReactMethod
    @SuppressWarnings({"unchecked", "unused"})
    public void setConversationTitle(    
            String convoID,        
            String title,
            Promise promise) {

        try {
            WritableArray writableArray = new WritableNativeArray();

            if (!layerClient.isConnected()) {
                layerClient.connect();
            }

            Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();

            if(!conversation.getId().toString().equals(convoID) || conversation == null ) {               
                conversation = fetchConvoWithId(convoID, layerClient);
            }

            conversation.putMetadataAtKeyPath("title", title);

            writableArray.pushString(YES);
            promise.resolve(writableArray);

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "unused"})
    public void sendMessageToConvoID(
            String messageText,
            String convoID,
            Promise promise) {

        try {

            if (!layerClient.isConnected()) {
                layerClient.connect();
            }

            Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();

            if(!conversation.getId().toString().equals(convoID) || conversation == null ) {               
                conversation = fetchConvoWithId(convoID, layerClient);
            }

            MessagePart messagePart = layerClient.newMessagePart(messageText);

            Map<String, String> data = new HashMap();

            if (LayerkitSingleton.getInstance().getUserIdGlobal() == null) {
                Log.v(TAG, "User id is null");
                return;
            }

            data.put("user_id", LayerkitSingleton.getInstance().getUserIdGlobal());

            Identity identity = layerClient.getAuthenticatedUser();
            String title = identity != null ? identity.getDisplayName() : "New Message";

            MessageOptions options = new MessageOptions();
            PushNotificationPayload payload = new PushNotificationPayload.Builder()
                    .text(messageText)
                    .title(title)
                    .data(data)
                    .build();


            options.defaultPushNotificationPayload(payload);

            Message message = layerClient.newMessage(options, Collections.singletonList(messagePart));

            conversation.send(message);
            promise.resolve(YES);

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }
/*
    @ReactMethod
    @SuppressWarnings({"unchecked", "unused"})
    public void sendMessageToUserIDs(
            String messageText,
            ReadableArray userIDs,
            Promise promise) {

        try {

            if (!layerClient.isConnected()) {
                layerClient.connect();
            }

            Conversation conversation = fetchLayerConversationWithParticipants(userIDs, layerClient);

            MessagePart messagePart = layerClient.newMessagePart(messageText);

            Map<String, String> data = new HashMap();

            if (LayerkitSingleton.getInstance().getUserIdGlobal() == null) {
                Log.v(TAG, "User id is null");
                return;
            }

            data.put("user_id", LayerkitSingleton.getInstance().getUserIdGlobal());

            Identity identity = layerClient.getAuthenticatedUser();
            String title = identity != null ? identity.getDisplayName() : "New Message";

            MessageOptions options = new MessageOptions();
            PushNotificationPayload payload = new PushNotificationPayload.Builder()
                    .text(messageText)
                    .title(title)
                    .data(data)
                    .build();


            options.defaultPushNotificationPayload(payload);

            Message message = layerClient.newMessage(options, Collections.singletonList(messagePart));

            conversation.send(message);
            promise.resolve(YES);

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }
*/
    /* ***************************************************************************** */
    /*                                                                               */
    /* BUSINESS METHODS                                                              */
    /*                                                                               */
    /* ***************************************************************************** */

    @SuppressWarnings("unchecked")
    private Conversation fetchLayerConversationWithParticipants(
            ReadableArray userIDs,
            LayerClient client) {

        String[] userIDsArray = new String[userIDs.size()];

        for (int i = 0; i < userIDs.size(); i++) {
            userIDsArray[i] = userIDs.getString(i);
        }

        Query query = Query.builder(Conversation.class)
                .predicate(new Predicate(Conversation.Property.PARTICIPANTS, Predicate.Operator.EQUAL_TO, userIDsArray))
                .build();

        List results = client.executeQuery(query, Query.ResultType.OBJECTS);

        if (results != null && results.size() > 0) {
            return (Conversation) results.get(0);
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

    @SuppressWarnings("unchecked")
    private Conversation fetchConvoWithId(
            String convoID,
            LayerClient client) {

        Query query = Query.builder(Conversation.class)
                .predicate(new Predicate(Conversation.Property.ID, Predicate.Operator.EQUAL_TO, convoID))
                .build();

        List<Conversation> results = client.executeQuery(query, Query.ResultType.OBJECTS);
        if (results != null) {
            if (results.size() > 0) {
                return results.get(0);
            }
        }

        return null;
    }



    public ReactApplicationContext getReactContext() {
        return reactContext;
    }
}
