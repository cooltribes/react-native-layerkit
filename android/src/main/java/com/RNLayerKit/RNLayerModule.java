package com.RNLayerKit;


import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.uimanager.IllegalViewOperationException;

import com.layer.sdk.LayerClient;

public class RNLayerModule extends ReactContextBaseJavaModule {

  ReactApplicationContext reactContext;

  public RNLayerModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
  }

  private LayerClient layerClient;

  @Override
  public String getName() {
    return "RNLayerKit";
  }

  @ReactMethod
  public void connect(
    String appIDstr,
    Promise promise) {
    try {
      LayerClient.Options options = new LayerClient.Options();
      layerClient = LayerClient.newInstance(this.reactContext, appIDstr, options);
      layerClient.connect();
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  }

}
