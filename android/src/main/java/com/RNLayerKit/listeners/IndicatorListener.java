package com.RNLayerKit.listeners;

import com.layer.sdk.listeners.LayerTypingIndicatorListener;
import com.layer.sdk.LayerClient;
import com.RNLayerKit.react.RNLayerModule;
import android.util.Log;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.Identity;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.RNLayerKit.utils.ConverterHelper;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;

public class IndicatorListener implements LayerTypingIndicatorListener {

    private final static String TAG = LayerTypingIndicatorListener.class.getSimpleName();

    private RNLayerModule mRNLayerModule;
    private LayerClient layerClient;

    public IndicatorListener(RNLayerModule mRNLayerModule, LayerClient layerClient) {
        this.mRNLayerModule = mRNLayerModule;
        this.layerClient = layerClient;        
    }
    
    public void onResume() {
        //super.onResume();        
        // Register this Activity to receive remote typing indications from Layer
        layerClient.registerTypingIndicator(this);        
        Log.d(TAG, "********** Register IndicatorListener");
    }   
    public void onPause() {
        //super.onPause();
        // Stop receiving remote typing indications from Layer when this Activity pauses
        layerClient.unregisterTypingIndicator(this);
        Log.d(TAG, "********** Unregister IndicatorListener");
    }

    @Override
    public void onTypingIndicator(LayerClient client, Conversation conversation, Identity user, TypingIndicator indicator) {

        WritableMap writableMap = new WritableNativeMap();

        writableMap.putString("source", "LayerClient");
        writableMap.putString("type", "typingIndicator");
        writableMap.putString("identifier", conversation.getId().toString());             
        
        WritableArray writableArray = new WritableNativeArray();

        WritableMap participantMap = new WritableNativeMap();
        participantMap.putString("id", user.getUserId());
        participantMap.putString("fullname", user.getDisplayName());
        participantMap.putString("avatar_url", user.getAvatarImageUrl());
        writableArray.pushMap(participantMap);

        writableMap.putArray("participant", writableArray);            

        switch (indicator) {
            case STARTED:
                Log.d(TAG, "++++++++++++++++++++++++++++++STARTED");
                // This user started typing, so add them to the typing list.
                //mTypers.add(user.getDisplayName());
                writableMap.putString("event", "LYRTypingDidBegin");
                break;

            case PAUSED:
                Log.d(TAG, "++++++++++++++++++++++++++++++PAUSED");
                // Ignore pause, since we only show who is and is not typing.
                writableMap.putString("event", "LYRTypingDidPause");
                break;

            case FINISHED:
                Log.d(TAG, "++++++++++++++++++++++++++++++FINISHED");
                // This user isn't typing anymore, so remove them from the list.
                //mTypers.remove(user.getDisplayName());
                writableMap.putString("event", "LYRTypingDidEnd");
                break;
        }

        mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", writableMap);

    }

}