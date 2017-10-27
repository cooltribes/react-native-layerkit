package com.RNLayerKit.react;

import android.util.Log;

import com.RNLayerKit.listeners.AuthenticationListener;
import com.RNLayerKit.listeners.ChangeEventListener;
import com.RNLayerKit.listeners.IndicatorListener;
import com.RNLayerKit.listeners.ConnectionListener;
import com.RNLayerKit.listeners.SyncListener;

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
import com.layer.sdk.query.SortDescriptor;
import com.layer.sdk.messaging.Metadata;

import java.lang.Long;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.Nullable;
import java.io.InputStream;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import java.io.ByteArrayOutputStream;
import android.net.Uri;
import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Arrays;

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
    private SyncListener layerSyncListener;

    @SuppressWarnings("WeakerAccess")
    public RNLayerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
        ConverterHelper.setContext(reactContext);   // add context helper
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
            options.historicSyncPolicy(LayerClient.Options.HistoricSyncPolicy.FROM_LAST_MESSAGE);
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

            if (layerSyncListener == null) {
                layerSyncListener = new SyncListener(this, layerClient);
            }
            layerClient.registerSyncListener(layerSyncListener);  

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

            if (!layerClient.isConnected())  
                layerClient.connect();
            
            if(!layerClient.isAuthenticated())
                layerClient.authenticate();

            if(layerClient.isAuthenticated() && layerClient.isConnected())
              layerClient.setPresenceStatus(Presence.PresenceStatus.AVAILABLE);

            int count;
            count = getMessagesCount();

            WritableArray writableArray = new WritableNativeArray();
            writableArray.pushString(YES);
            writableArray.pushInt(count);

            layerClient.setAutoDownloadSizeThreshold(1024 * 100);
            layerClient.setAutoDownloadMimeTypes(Arrays.asList("image/jpg"));

            promise.resolve(writableArray);
        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }

    @SuppressWarnings("unchecked")
    private int getMessagesCount() {

        try {

            Query query = Query.builder(Message.class)
                .predicate(new Predicate(Message.Property.IS_UNREAD, Predicate.Operator.EQUAL_TO, true))
                .build();

            Long results = layerClient.executeQueryForCount(query);

            if (results != null) {
                return (int) (results + 0);
            }

        } catch (IllegalViewOperationException ignored) {
        }

        return 0;

    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "UnusedParameters", "unused"})
    public void getConversations(
            int limit,
            int offset,
            Promise promise) {

        try {
            WritableArray writableArray = new WritableNativeArray();

            Builder builder = Query.builder(Conversation.class)
                .sortDescriptor(new SortDescriptor(Conversation.Property.LAST_MESSAGE_RECEIVED_AT, SortDescriptor.Order.DESCENDING));

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
                    int count = getMessagesCount();
                    writableArray.pushInt(count);
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
    public void syncMessages(
            String convoID,
            ReadableArray userIDs,
            int limit,
            Promise promise) {

        WritableArray writableArray = new WritableNativeArray();

        if (convoID != null) {
            try {

                Conversation conversation = fetchConvoWithId(convoID, layerClient);

                if (conversation != null) {
                    LayerkitSingleton.getInstance().setConversationGlobal(conversation);            //// set conversation global
                }

                if(conversation != null && conversation.getHistoricSyncStatus().toString().equals("MORE_AVAILABLE")) {
                    conversation.syncMoreHistoricMessages(limit);
                }
               
                writableArray.pushString(YES);
                promise.resolve(writableArray);

            } catch (IllegalViewOperationException e) {
                promise.reject(e);
            }
        } else {
            Conversation conversation = fetchLayerConversationWithParticipants(userIDs, layerClient);

            if (conversation != null) {
                LayerkitSingleton.getInstance().setConversationGlobal(conversation);            //// set conversation global
            }
            try {
                
                if(conversation != null && conversation.getHistoricSyncStatus().toString().equals("MORE_AVAILABLE")) {
                    conversation.syncMoreHistoricMessages(limit);
                }
                
                writableArray.pushString(YES);
                promise.resolve(writableArray);

            } catch (IllegalViewOperationException e) {
                promise.reject(e);
            }
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

                Builder builder = Query.builder(Message.class)
                    .predicate(new Predicate(Message.Property.CONVERSATION, Predicate.Operator.EQUAL_TO, conversation))
                    .sortDescriptor(new SortDescriptor(Message.Property.POSITION, SortDescriptor.Order.DESCENDING))
                    .limit(limit)
                    .offset(offset);
                
                /*if (limit != 0) {
                    builder.limit(limit);
                }*/
                Query query = builder.build();
                List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
                
                if(conversation != null && conversation.getHistoricSyncStatus().toString().equals("MORE_AVAILABLE")) {
                    conversation.syncMoreHistoricMessages(limit);
                }
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
                Builder builder = Query.builder(Message.class)
                    .predicate(new Predicate(Message.Property.CONVERSATION, Predicate.Operator.EQUAL_TO, conversation))
                    .sortDescriptor(new SortDescriptor(Message.Property.POSITION, SortDescriptor.Order.DESCENDING))
                    .limit(limit)
                    .offset(offset);

                /*if (limit != 0) {
                    builder.limit(limit);
                }*/
                Query query = builder.build();
                List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
                
                if(conversation != null && conversation.getHistoricSyncStatus().toString().equals("MORE_AVAILABLE")) {
                    conversation.syncMoreHistoricMessages(limit);
                }
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
            //WritableArray writableArray = new WritableNativeArray();

            if (!layerClient.isConnected()) {
                layerClient.connect();
            }

            Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();

            if(!conversation.getId().toString().equals(convoID) || conversation == null ) {               
                conversation = fetchConvoWithId(convoID, layerClient);
            }

            conversation.putMetadataAtKeyPath("title", title);

            //writableArray.pushString(YES);
            //promise.resolve(writableArray);
            promise.resolve(YES);

        } catch (IllegalViewOperationException e) {
            promise.reject(e);
        }

    }

    @ReactMethod
    @SuppressWarnings({"unchecked", "unused"})
    public void sendMessageToConvoID(
            ReadableArray parts,
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

            List<MessagePart> partes = new ArrayList<MessagePart>();

            MessagePart messagePart;
            for (int i = 0; i < parts.size(); i++) {
                
                if(parts.getMap(i).getString("type").equals("image/jpg")) {

                    Uri uri = Uri.parse(parts.getMap(i).getString("message"));

                    try {
                        //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!imagen: %s", parts.getMap(i).getString("type").toString()));
                        InputStream imageStream = this.reactContext.getContentResolver().openInputStream(uri);
                        Bitmap bm = BitmapFactory.decodeStream(imageStream);
                        ByteArrayOutputStream baos = new ByteArrayOutputStream();
                        bm.compress(Bitmap.CompressFormat.JPEG, 100, baos); //bm is the bitmap object
                        byte[] decodedBytes = baos.toByteArray();
                      
                        messagePart = layerClient.newMessagePart("image/jpg", decodedBytes);                        
                        partes.add(i,messagePart);
                    }
                    catch (FileNotFoundException ex) {
                        Log.d(TAG, String.format("Error load image: %s", ex.toString()));
                    }
                } else {
                    //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!texto: %s", parts.getMap(i).getString("type").toString()));
                    messagePart = layerClient.newMessagePart(parts.getMap(i).getString("type"), parts.getMap(i).getString("message").getBytes());                    
                    partes.add(i,messagePart);
                }                
            }

            ////////////////////////////////////////////////////////

            Metadata metadata = conversation.getMetadata(); 
            Map<String, String> data = new HashMap();       
            String title = "";
            String type;

            Identity identity = null;
            identity = layerClient.getAuthenticatedUser();

            Set<Identity> participants = conversation.getParticipants();        

            if(participants.size() > 2) {
                type = "group";
                if(metadata.get("title") != null) {
                    title = metadata.get("title").toString();            
                } else {                
                    for (Identity participant : participants) {
                        title = title + participant.getDisplayName() + ", ";
                    }
                } 
            }  else {
                type = "chat";
                title = identity != null ? identity.getDisplayName() : "New Message";
            }

            data.put("name", identity.getDisplayName().toString());
            data.put("type", type.toString());

            String texto =  parts.getMap(0).getString("message");
            if(participants.size() > 2) {
                texto = identity.getDisplayName() + ": " + texto;
            }

            MessageOptions options = new MessageOptions();
            PushNotificationPayload payload = new PushNotificationPayload.Builder()
                .text(texto)
                .title(title)
                .data(data)
                .build();


            options.defaultPushNotificationPayload(payload);

            //////////////////////////////////////////////////////////

            Message message = layerClient.newMessage(options, partes);

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
