package com.RNLayerKit.utils;

import android.annotation.SuppressLint;
import android.util.Log;

import com.RNLayerKit.singleton.LayerkitSingleton;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.layer.sdk.changes.LayerChange;
import com.layer.sdk.changes.LayerChangeEvent;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.Identity;
import com.layer.sdk.messaging.LayerObject;
import com.layer.sdk.messaging.Message;
import com.layer.sdk.messaging.MessagePart;
import com.layer.sdk.messaging.Presence;
import com.layer.sdk.messaging.Metadata;

import java.nio.charset.Charset;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TimeZone;
import java.util.Date;

import com.facebook.react.bridge.ReactApplicationContext;
import android.graphics.BitmapFactory;
import android.graphics.Bitmap;
import java.io.ByteArrayOutputStream;
import android.net.Uri;
import android.provider.MediaStore;

public class ConverterHelper {

    private final static String TAG = ConverterHelper.class.getSimpleName();
    private final static String DATE_FORMAT_NOW = "yyyy-MM-dd'T'HH:mm'Z'";
    private final static Charset UTF8_CHARSET = Charset.forName("UTF-8");
    public static ReactApplicationContext reactContext;

    public static WritableMap convertChangesToArray(LayerChangeEvent event) {

        List<LayerChange> changes = event.getChanges();
        WritableArray writableArray = new WritableNativeArray();

        for (int i = 0; i < changes.size(); i++) {
            LayerChange change = changes.get(i);

            WritableMap writableMap = new WritableNativeMap();

            if (change.getObjectType() == LayerObject.Type.CONVERSATION) {
                writableMap.putString("object", "LYRConversation");
                Conversation conversation = (Conversation) change.getObject();
                writableMap.putString("identifier", conversation.getId().toString());
                writableMap.putMap("conversation", conversationToWritableMap(conversation));
                writableMap.putString("historicSyncStatus", conversation.getHistoricSyncStatus().toString());

                // Sync More Init Sync 
                if(change.getChangeType() == LayerChange.Type.INSERT) {
                    conversation.syncMoreHistoricMessages(24);
                    //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!ojoooooooooooooo: %s", conversation.toString()));
                }
            }

            if (change.getObjectType() == LayerObject.Type.MESSAGE) {
                writableMap.putString("object", "LYRMessage");
                Message message = (Message) change.getObject();
                writableMap.putString("identifier", message.getId().toString());
                writableMap.putMap("message", messageToWritableMap(message));
                writableMap.putMap("conversation", conversationToWritableMap(message.getConversation()));
            }


            if (change.getAttributeName() != null) {
                writableMap.putString("attribute", change.getAttributeName());
                if(change.getAttributeName() == "presenceStatus") {
                    Identity participant = (Identity) change.getObject();
                    //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!result: %s", participant.getUserId().toString()));
                    writableMap.putString("user", participant.getUserId().toString());
                }
            }

            if (change.getOldValue() != null) {
                writableMap.putString("changeFrom", change.getOldValue().toString());
            }

            if (change.getNewValue() != null) {
                writableMap.putString("changeTo", change.getNewValue().toString());
            }

            switch (change.getChangeType()) {
                case INSERT:
                    writableMap.putString("type", "LYRObjectChangeTypeCreate");
                    break;
                case UPDATE:
                    writableMap.putString("type", "LYRObjectChangeTypeUpdate");
                    break;
                case DELETE:
                    writableMap.putString("type", "LYRObjectChangeTypeDelete");
                    break;
            }

            writableArray.pushMap(writableMap);
        }

        WritableMap params = Arguments.createMap();
        params.putString("source", "LayerClient");
        params.putString("type", "objectsDidChange");
        params.putArray("data", writableArray);

        return params;

    }

    public static WritableArray conversationsToWritableArray(List<Conversation> conversations) {
        WritableArray conversationsArray = new WritableNativeArray();

        if (conversations == null) {
            return null;
        }
        for (int i = 0; i < conversations.size(); i++) {
            WritableMap conversationMap = conversationToWritableMap(conversations.get(i)); 
            if(conversationMap != null) {
                conversationsArray.pushMap(conversationMap);
            }
        }

        return conversationsArray;

    }

    private static WritableMap conversationToWritableMap(Conversation conversation) {
        WritableMap conversationMap = new WritableNativeMap();

        if (conversation == null) {
            return null;
        }

        conversationMap.putString("identifier", conversation.getId().toString());
        conversationMap.putInt("hasUnreadMessages", conversation.getTotalUnreadMessageCount());
        conversationMap.putBoolean("deliveryReceiptsEnabled", conversation.isDeliveryReceiptsEnabled());
        conversationMap.putBoolean("isDeleted", conversation.isDeleted());
        conversationMap.putString("historicSyncStatus", conversation.getHistoricSyncStatus().toString());
        
        Metadata metadata = conversation.getMetadata();
        
        conversationMap.putString("metadata", metadata.toString());
        if(metadata.get("title") != null) {
            conversationMap.putString("title", metadata.get("title").toString());            
        }

        Set<Identity> participants = conversation.getParticipants();

        if(participants.size() == 0) {             // Participants vacio
            return null;
        }

        WritableArray writableArray = new WritableNativeArray();
        for (Identity participant : participants) {
            WritableMap participantMap = new WritableNativeMap();
            participantMap.putString("id", participant.getUserId());
            participantMap.putString("fullname", participant.getDisplayName());
            participantMap.putString("avatar_url", participant.getAvatarImageUrl());

            Presence.PresenceStatus status =  participant.getPresenceStatus();
            String participantStatus = "offline";        
            if(status != null)
                switch (status) {
                    case AVAILABLE:            
                        participantStatus = "available";
                        break;
                    case AWAY:
                        participantStatus = "away";
                        break;
                    case BUSY:
                        participantStatus = "busy";
                        break;
                    case OFFLINE:
                        participantStatus = "offline";
                        break;
                    case INVISIBLE:
                        participantStatus = "invisible";
                        break;                
                }
            //Log.d(TAG, String.format("result: %s", status.toString()));
            participantMap.putString("status", participantStatus);

            writableArray.pushMap(participantMap);
        }
        conversationMap.putArray("participants", writableArray);

        // TODO Put createdAt from MessagePart
        // conversationMap.putString("createdAt", conversation.createdAt.toString());
        conversationMap.putInt("totalNumberOfUnreadMessages", conversation.getTotalUnreadMessageCount());
        conversationMap.putMap("lastMessage", messageToWritableMap(conversation.getLastMessage()));

        return conversationMap;

    }

    public static WritableArray messagesToWritableArray(List<Message> messages) {
        WritableArray messagesArray = new WritableNativeArray();

        if (messages == null) {
            return null;
        }
        for (int i = 0; i < messages.size(); i++) {
            messagesArray.pushMap(messageToWritableMap(messages.get(i)));
        }

        return messagesArray;

    }

    @SuppressLint("SimpleDateFormat")
    private static WritableMap messageToWritableMap(Message message) {
        WritableMap messageMap = new WritableNativeMap();

        if (message == null) {
            Log.d(TAG, "Message is null");
            return null;
        }

        messageMap.putString("identifier", message.getId().toString());
        messageMap.putBoolean("isDeleted", message.isDeleted());
        messageMap.putBoolean("isSent", message.isSent());
        messageMap.putDouble("position",(double)  message.getPosition());

        if (LayerkitSingleton.getInstance().getUserIdentityGlobal() != null) {
            Message.RecipientStatus recipientStatus = message.getRecipientStatus(LayerkitSingleton.getInstance().getUserIdentityGlobal());
            if(recipientStatus != null) {
                messageMap.putString("Status", recipientStatus.toString());
            } else {
                messageMap.putString("Status", null);
            }
        }

        Map<Identity, Message.RecipientStatus> recipientStatus = message.getRecipientStatus();
        WritableNativeMap mapRecipientStatus = new WritableNativeMap();
        for (Map.Entry<Identity, Message.RecipientStatus> recipient : recipientStatus.entrySet()) {
            if(recipient.getValue() != null) {
                mapRecipientStatus.putString(recipient.getKey().getUserId(), recipient.getValue().toString());
            }
        }
        messageMap.putMap("recipientStatus", mapRecipientStatus);

        DateFormat simpleDateFormat = new SimpleDateFormat(DATE_FORMAT_NOW);
        TimeZone timeZone = TimeZone.getTimeZone("UTC");
        simpleDateFormat.setTimeZone(timeZone);
        Date date_now = new Date();                                     // now()

        if (message.getReceivedAt() != null) {
            messageMap.putString("receivedAt", simpleDateFormat.format(message.getReceivedAt()));   
        } else {
            messageMap.putString("receivedAt", simpleDateFormat.format(date_now));
        }

        if (message.getSentAt() != null) {
            messageMap.putString("sentAt", simpleDateFormat.format(message.getSentAt()));
        }

        messageMap.putArray("parts", messagePartsToWritableMap(message.getMessageParts()));
        Identity identity = message.getSender();
        if (identity != null) {
            messageMap.putString("sender", identity.getUserId());
            
            ///////////////////User for Message //////////////////////////
            WritableMap userMap = new WritableNativeMap();
            userMap.putString("_id", identity.getUserId());
            userMap.putString("name", identity.getDisplayName());
            userMap.putString("avatar", identity.getAvatarImageUrl());

            Presence.PresenceStatus status =  identity.getPresenceStatus();
            String participantStatus = "offline";        
            if(status != null)
                switch (status) {
                    case AVAILABLE:            
                        participantStatus = "available";
                        break;
                    case AWAY:
                        participantStatus = "away";
                        break;
                    case BUSY:
                        participantStatus = "busy";
                        break;
                    case OFFLINE:
                        participantStatus = "offline";
                        break;
                    case INVISIBLE:
                        participantStatus = "invisible";
                        break;                
                }
            //Log.d(TAG, String.format("result: %s", status.toString()));
            userMap.putString("status", participantStatus);

            messageMap.putMap("user",userMap);
            /////////////////////////////////////////////
        }

        if (message.getMessageParts().get(0).getMimeType().equals("text/plain")) {
            if(message.getMessageParts().get(0).getData() != null) {
                messageMap.putString("text", new String(message.getMessageParts().get(0).getData(), UTF8_CHARSET));
            }
        }

        return messageMap;

    }

    private static WritableArray messagePartsToWritableMap(List<MessagePart> messageParts) {
        WritableArray messagePartArray = new WritableNativeArray();

        if (messageParts == null) {
            return null;
        }
        for (int i = 0; i < messageParts.size(); i++) {
            messagePartArray.pushMap(messagePartToWritableMap(messageParts.get(i)));
        }

        return messagePartArray;
    }

    private static WritableMap messagePartToWritableMap(MessagePart messagePart) {
        WritableMap messagePartMap = new WritableNativeMap();

        if (messagePart == null) {
            return null;
        }

        messagePartMap.putString("identifier", messagePart.getId().toString());
        messagePartMap.putString("MIMEType", messagePart.getMimeType());

        if (messagePart.getMimeType().equals("text/plain")) {
            //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!txt messagePart: %s", messagePart.toString()));
            if(messagePart.getData() != null) {
                String s = new String(messagePart.getData(), UTF8_CHARSET);
                messagePartMap.putString("data", s);
            }
        }
        if (messagePart.getMimeType().equals("image/jpg")) {            

            //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!image messagePart: %s", messagePart.toString()));
            Bitmap image;
            byte[] myData = messagePart.getData();

            if(myData != null) {
                image = BitmapFactory.decodeByteArray(myData, 0, myData.length);            
            
                if(image != null) {
                    //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!image != null: %s", image.toString()));
                    ByteArrayOutputStream bytes = new ByteArrayOutputStream();
                    image.compress(Bitmap.CompressFormat.JPEG, 100, bytes);
                    String path = MediaStore.Images.Media.insertImage(reactContext.getContentResolver(), image, "", null);                    
                    //Log.d(TAG, String.format("!!!!!!!!!!!!!!!!!!!!URI: %s", Uri.parse(path).toString()));
                    messagePartMap.putString("data", Uri.parse(path).toString());
                }
            }
        }
        messagePartMap.putDouble("size", messagePart.getSize());
        messagePartMap.putInt("transferStatus", messagePart.getTransferStatus().getValue());

        return messagePartMap;
    }

    public static void setContext(ReactApplicationContext context) {
        reactContext = context;
    }
}
