package com.RNLayerKit.listeners;

import com.layer.sdk.LayerClient;
import com.layer.sdk.listeners.LayerSyncListener;
import com.RNLayerKit.react.RNLayerModule;
import android.util.Log;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.layer.sdk.exceptions.LayerException;
import java.util.List;

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

        WritableMap writableMap = new WritableNativeMap();

        writableMap.putString("source", "LayerClient");
        writableMap.putString("type", syncType.toString());

        if(syncType.toString().equals("HISTORIC")) {
            mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", writableMap);
        }
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

        WritableMap writableMap = new WritableNativeMap();

        writableMap.putString("source", "LayerClient");
        writableMap.putString("type", syncType.toString());

        if(syncType.toString().equals("HISTORIC")) {
            mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", writableMap);
        }
    }

    @Override
    public void onSyncError(LayerClient client, List<LayerException> exceptions) {
        // Sync has thrown an error
        Log.v(TAG, "ErrorSync");
    }
}