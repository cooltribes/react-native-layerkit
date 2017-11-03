package com.RNLayerKit.listeners;

import com.layer.sdk.LayerClient;
import com.layer.sdk.listeners.LayerSyncListener;
import com.RNLayerKit.react.RNLayerModule;
import android.util.Log;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.layer.sdk.exceptions.LayerException;
import java.util.List;

import com.RNLayerKit.singleton.LayerkitSingleton;
import com.layer.sdk.messaging.Conversation;

public class SyncListener implements LayerSyncListener {

    private final static String TAG = LayerSyncListener.class.getSimpleName();

    private RNLayerModule mRNLayerModule;

    public SyncListener(RNLayerModule mRNLayerModule, LayerClient layerClient) {
        this.mRNLayerModule = mRNLayerModule;      
    }

    @Override
    public void onBeforeSync(LayerClient client, SyncType syncType) {
        // LayerClient is starting synchronization
        Log.v(TAG, "onBeforeSync");

        sendEvent("init");    
    }

    @Override
    public void onSyncProgress(LayerClient client, SyncType syncType, int progress) {
        // LayerClient synchronization progress
        Log.v(TAG, "onSyncProgress : " + syncType.toString() + " %: " +progress);
    }

    @Override
    public void onAfterSync(LayerClient client, SyncType syncType) {
        // LayerClient has finished synchronization
        Log.v(TAG, "finishedSync" + syncType.toString());

        sendEvent("finish");        
    }

    @Override
    public void onSyncError(LayerClient client, List<LayerException> exceptions) {
        // Sync has thrown an error
        Log.v(TAG, "ErrorSync");

        sendEvent("error");        
    }

    public void sendEvent(String status) {
        
        // Conversation Sync
        Conversation conversation = LayerkitSingleton.getInstance().getConversationSync();
        
        if(conversation != null) {

            WritableMap writableMap = new WritableNativeMap();

            writableMap.putString("source", "LayerClient");
            writableMap.putString("type", "SyncMessages");
            writableMap.putString("status", status);
            writableMap.putString("identifier", conversation.getId().toString());

            if(status == "finish") {
                writableMap.putArray("messages", mRNLayerModule.get_messages_layer(conversation.getId().toString(), LayerkitSingleton.getInstance().getLimit(), 0) );
            }

            mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", writableMap);
            Log.v(TAG, "++++++++++++++++++ SEND_EVENT SYNC -----------> " + status);
        }
    }    

}