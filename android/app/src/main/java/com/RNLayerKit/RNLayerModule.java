package com.RNLayerKit;


import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

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
    string appIDstr) {
    try {
      layerClient.connect();
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  }

}
