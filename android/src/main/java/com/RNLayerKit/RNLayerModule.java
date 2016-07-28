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
  public static String userIDGlobal;

  private MyAuthenticationListener authenticationListener;

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

      if(authenticationListener == null)
        authenticationListener = new MyAuthenticationListener(this); 
      layerClient.registerAuthenticationListener(authenticationListener); 
            
      layerClient.connect();
      promise.resolve('YES');
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  }

  @ReactMethod
  public void authenticateLayerWithUserID(
    String userID,
    Promise promise) {
    try {
      userIDGlobal = userID;
      layerClient.authenticate();
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  } 

}