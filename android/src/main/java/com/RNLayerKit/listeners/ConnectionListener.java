package com.RNLayerKit.listeners;

import com.layer.sdk.LayerClient;
import com.layer.sdk.listeners.LayerConnectionListener;

import com.RNLayerKit.react.RNLayerModule;
import android.util.Log;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.Identity;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.RNLayerKit.utils.ConverterHelper;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.layer.sdk.exceptions.LayerException;

public class ConnectionListener implements LayerConnectionListener {

    private final static String TAG = LayerConnectionListener.class.getSimpleName();

    private RNLayerModule mRNLayerModule;
    private LayerClient layerClient;

    public ConnectionListener(RNLayerModule mRNLayerModule, LayerClient layerClient) {
        this.mRNLayerModule = mRNLayerModule;
        this.layerClient = layerClient;        
    }
    
    @Override
     // Called when the LayerClient establishes a network connection
     public void onConnectionConnected(LayerClient layerClient) {
        // Ask the LayerClient to authenticate. If no auth credentials are present,
        // an authentication challenge is issued
        Log.d(TAG, "********** ConnectionListener Connected");
        layerClient.authenticate();
        //Log.d(TAG, String.format("result: %s", result));
     }
     @Override
     // Called when the LayerClient Disconnected network connection
     public void onConnectionDisconnected(LayerClient layerClient) {
        Log.d(TAG, "********** ConnectionListener Disconnected");
     }
     @Override
     // Called when the LayerClient ConnectionError network connection
     public void onConnectionError(LayerClient client, LayerException exception) {        
        Log.d(TAG, "********** ConnectionListener ConnectionError");        
     }
}