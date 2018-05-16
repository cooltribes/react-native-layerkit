package com.RNLayerKit.listeners;

import com.RNLayerKit.react.RNLayerModule;
import com.RNLayerKit.utils.ConverterHelper;
import com.layer.sdk.changes.LayerChangeEvent;
import com.layer.sdk.listeners.LayerChangeEventListener;
import com.facebook.react.bridge.WritableMap;

import com.layer.sdk.changes.LayerChange;
import java.util.List;
import com.facebook.react.bridge.Arguments;
import com.layer.sdk.messaging.LayerObject;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.RNLayerKit.singleton.LayerkitSingleton;
import com.layer.sdk.messaging.Message;
import java.util.Set;
import com.layer.sdk.messaging.Identity;
import com.layer.sdk.messaging.Conversation;
import android.util.Log;
import com.layer.sdk.messaging.Metadata;

public class ChangeEventListener implements LayerChangeEventListener {

    private RNLayerModule mRNLayerModule;

    public ChangeEventListener(RNLayerModule mRNLayerModule) {
        this.mRNLayerModule = mRNLayerModule;
    }

    @Override
    public void onChangeEvent(LayerChangeEvent event) {

    	List<LayerChange> changes = event.getChanges();

    	WritableMap params = Arguments.createMap();

    	WritableArray writableArray = new WritableNativeArray();

    	for (int i = 0; i < changes.size(); i++) {

            LayerChange change = changes.get(i);

	        WritableMap writableMap = new WritableNativeMap();

            boolean hasData = false;

            switch (change.getObjectType()) {

            	case MESSAGE:

                    // Update
            		if(change.getChangeType() == LayerChange.Type.UPDATE) {
            			
            			switch (change.getAttributeName()) {

            				case "recipientStatus":

            					Message message = (Message) change.getObject();
            					Set<Identity> participants = message.getConversation().getParticipants();           					
            					
            					// Caso 1: conversation opened || chat 1-1
            					if(LayerkitSingleton.getInstance().getConversationGlobal() != null || participants.size() == 2) {
            						writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                                    hasData = true;
            						// Log.v("CHANGESSS", "Case 1 -->"  + LayerkitSingleton.getInstance().getConversationGlobal().getId().toString());
            					}
            					break;

            				case "isDeleted":
                            case "isSent":

		            			writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                                hasData = true;
            				    // Log.v("CHANGESSS", "is sent is delete-->"  + writableMap.toString());
                                break;
            			}
	            	}

                    // Insert
                    if(change.getChangeType() == LayerChange.Type.INSERT) {
                        
                        Message message = (Message) change.getObject();

                        Conversation conversationChange = message.getConversation();
                        String lastPosition = null;
                        
                        if(conversationChange != null) {
                            Metadata metadata = conversationChange.getMetadata();
                            if(metadata.get("lastPosition") != null) {
                                lastPosition = metadata.get("lastPosition").toString();
                            }
                        }

                        if(lastPosition != null) {
                            if(Long.parseLong(lastPosition) <= message.getPosition()) {
                                // Log.v("\n\n********************", "akiiiiiiiiiiiiiiiii -->"  + message.getId().toString());
                                Conversation conversation = LayerkitSingleton.getInstance().getConversationGlobal();
                                if(conversation != null) {
                                    if(conversation.getId().toString().equals(message.getConversation().getId().toString())) {

                                        writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                                        hasData = true;
                                        // Mark Readed
                                        Identity sender = message.getSender();
                                        if(!sender.getUserId().equals(LayerkitSingleton.getInstance().getUserIdGlobal())) {
                                            message.markAsRead();
                                        }
                                        // Update Metadata
                                        conversation.putMetadataAtKeyPath("lastPosition", Long.toString(message.getPosition()));

                                    }
                                }
                            }
                        }
                    }

                    break;


                case CONVERSATION:

                    // Update
	            	if(change.getChangeType() == LayerChange.Type.UPDATE) {
	            		
	            		switch (change.getAttributeName()) {

            				case "lastMessage":

            					Conversation conversationGlobal = (Conversation) LayerkitSingleton.getInstance().getConversationGlobal();
            					Conversation conversationChange = (Conversation) change.getObject();

            					// Caso 2: conversation opened && same conversation event
            					if(conversationGlobal != null) {
            						if(conversationGlobal.getId().toString().equals(conversationChange.getId().toString())) {
            							writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                                        hasData = true;
                                    }
            					}
            					break;

            				case "totalUnreadMessageCount":
            				case "metadata":
            				case "participants":

								writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                                hasData = true;
            					params.putInt("badge", mRNLayerModule.getMessagesCount());
            					break;
            			}
	            	}

	            	// Create
	            	if(change.getChangeType() == LayerChange.Type.INSERT) {
	            		writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                        hasData = true;
	            	}
                    break;

                case IDENTITY:

                    writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                    hasData = true;
                    break;

                case MESSAGE_PART:
                    
                    writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);                    
                    hasData = true;
                    break;
            }

            if(hasData == true) {
                writableArray.pushMap(writableMap);
            }
        }

        params.putString("source", "LayerClient");
        params.putString("type", "objectsDidChange");
        params.putArray("data", writableArray);

        // Send Event React
        mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", params);
    }
}