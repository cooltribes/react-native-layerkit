package com.RNLayerKit.listeners;

import com.RNLayerKit.react.RNLayerModule;
import com.RNLayerKit.utils.ConverterHelper;
import com.layer.sdk.changes.LayerChangeEvent;
import com.layer.sdk.listeners.LayerChangeEventListener;
import com.facebook.react.bridge.WritableMap;

public class ChangeEventListener implements LayerChangeEventListener {

    private RNLayerModule mRNLayerModule;

    public ChangeEventListener(RNLayerModule mRNLayerModule) {
        this.mRNLayerModule = mRNLayerModule;
    }

    @Override
    public void onChangeEvent(LayerChangeEvent event) {

        WritableMap params = ConverterHelper.convertChangesToArray(event, mRNLayerModule);
        mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", params);

    }
}