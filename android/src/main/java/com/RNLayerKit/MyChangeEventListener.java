package com.RNLayerKit;

import android.os.AsyncTask;
import android.util.Log;

import com.layer.sdk.LayerClient;
import com.layer.sdk.exceptions.LayerException;
import com.layer.sdk.changes.LayerChangeEvent;
import com.layer.sdk.changes.LayerChange;
import com.layer.sdk.listeners.LayerChangeEventListener;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.LayerObject;
import com.layer.sdk.messaging.Message;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.bridge.Arguments;


import android.util.Log;
import java.util.List;

public class MyChangeEventListener implements LayerChangeEventListener {

    private static final String TAG = MyChangeEventListener.class.getSimpleName();

    private RNLayerModule main_activity;

    public MyChangeEventListener(RNLayerModule ma) {
        main_activity = ma;
    }
    public void onChangeEvent(LayerChangeEvent event){
      Log.v("RAFAonChangeEvent", event.toString());
      List<LayerChange> changes = event.getChanges();
      WritableArray writableArray = new WritableNativeArray();
      for (int i=0; i < changes.size() ; i++){
        LayerChange change = changes.get(i);
        Log.v("RAFAchanges", change.toString());
        WritableMap writableMap = new WritableNativeMap();
            Object changeObject = change.getObject();
            writableMap.putString("object",changeObject.getClass().getSimpleName());
            if (change.getObjectType() == LayerObject.Type.CONVERSATION) {            
              Conversation conversation = (Conversation) change.getObject();
              writableMap.putString("identifier",conversation.getId().toString()); 
              writableMap.putString("object","LYRConversation"); 
              writableMap.putMap("conversation",main_activity.conversationToWritableMap(conversation));
              Log.v("RafaMessage", conversation.toString());          
              Log.v("RAFAconversation", "Conversation " + conversation.getId() + " attribute " +
                      change.getAttributeName() + " was changed from " + change.getOldValue() +
                      " to " + change.getNewValue());
              switch (change.getChangeType()) {
                  case INSERT:
                    writableMap.putString("type","LYRObjectChangeTypeCreate");
                    break;
                  case UPDATE:
                    writableMap.putString("type","LYRObjectChangeTypeUpdate");
                    break;
                  case DELETE:
                    writableMap.putString("type","LYRObjectChangeTypeDelete");
                    break;
              }

            } else if (change.getObjectType() == LayerObject.Type.MESSAGE) {

                Message message = (Message) change.getObject();
                writableMap.putString("identifier",message.getId().toString());
                writableMap.putString("object","LYRMessage");
                writableMap.putMap("message",main_activity.messageToWritableMap(message));
                Log.v("RafaMessage", message.toString());
                Log.v("RafaMessage", "Message " + message.getId() + " attribute " + change
                        .getAttributeName() + " was changed from " + change.getOldValue() + " to " +
                        "" + change.getNewValue());
                switch (change.getChangeType()) {
                    case INSERT:
                      writableMap.putString("type","LYRObjectChangeTypeCreate");
                      break;
                    case UPDATE:
                      writableMap.putString("type","LYRObjectChangeTypeUpdate");
                      break;
                    case DELETE:
                      writableMap.putString("type","LYRObjectChangeTypeDelete");
                      break;
                }
            }       
            writableArray.pushMap(writableMap);
      }
      WritableMap params = Arguments.createMap();
      params.putString("source","LayerClient");
      params.putString("type","objectsDidChange");
      params.putArray("data",writableArray);
      main_activity.sendEvent(main_activity.reactContext,"LayerEvent",params);
    }
}