package com.RNLayerKit;


import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.uimanager.IllegalViewOperationException;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;

import com.layer.sdk.LayerClient;
import com.layer.sdk.messaging.Conversation;
import com.layer.sdk.messaging.LayerObject;
import com.layer.sdk.messaging.Message;
import com.layer.sdk.messaging.MessageOptions;
import com.layer.sdk.messaging.MessagePart;
import com.layer.sdk.messaging.Metadata;
import java.util.List;
import java.util.ArrayList;
import com.layer.sdk.query.Predicate;
import com.layer.sdk.query.Query;
import com.layer.sdk.query.SortDescriptor;
import com.layer.sdk.query.Queryable;

import com.google.gson.Gson;

import java.util.Iterator;
import javax.annotation.Nullable;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.util.Log;

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
      promise.resolve("YES");
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
      promise.resolve("YES");
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  } 

  @ReactMethod
  public void getConversations(
    int limit,
    int offset,
    Promise promise) {   

    try {
      WritableArray writableArray = new WritableNativeArray();

      Query query = Query.builder(Conversation.class)
              .limit(10)
              .build();

      List<Conversation> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
      if (results != null) {
          writableArray.pushString("YES");
          
          String jsonResults = new Gson().toJson(results);
           Log.v("RAFA", jsonResults);
          
          try {
          //JSONArray jsonArray = new JSONArray("{'a':1,'b':2}");
            JSONArray jsonArray = new JSONArray(jsonResults);
          } catch (JSONException e) {
            Log.e("RAFA", "Invalid JSON string: " + jsonResults, e);
            return null;
          } 
          //JSONObject jsonObject = new JSONObject(results.get(0));
          writableArray.pushArray(jsonArrayToWritableArray(jsonArray));
          //writableArray.pushMap(jsonToWritableMap(jsonObject));
          promise.resolve(writableArray);
      }
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  } 

  @ReactMethod
  public void getMessages(
    String convoID
    int limit,
    int offset,
    Promise promise) {
    try {

      Query query = Query.builder(Message.class)
              .predicate(new Predicate(Message.Property.CONVERSATION, Predicate
                .Operator.EQUAL_TO, this.fetchConvoWithId(convoID,layerClient)))
              .limit(10)
              .build();

      List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
      if (results != null) {
          promise.resolve("YES");
      }
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  }

  private List<Conversation> fetchConvoWithId(
    String convoID,
    LayerClient client
    ) {

    Query query = Query.builder(Conversation.class)
    .predicate(new Predicate(Conversation.Property.ID, Predicate.Operator.EQUAL_TO, convoID))
    .build();

    List<Conversation> results = client.executeQuery(query, Query.ResultType.OBJECTS);
    if (results != null) {
      results.get(0);
    } 
    List<Conversation> returnValue = new List<Conversation>();;
    return returnValue;
  }

  @Nullable
  public static WritableMap jsonToWritableMap(JSONObject jsonObject) {
      WritableMap writableMap = new WritableNativeMap();

      if (jsonObject == null) {
          return null;
      }


      Iterator<String> iterator = jsonObject.keys();
      if (!iterator.hasNext()) {
          return null;
      }

      while (iterator.hasNext()) {
          String key = iterator.next();

          try {
              Object value = jsonObject.get(key);

              if (value == null) {
                  writableMap.putNull(key);
              } else if (value instanceof Boolean) {
                  writableMap.putBoolean(key, (Boolean) value);
              } else if (value instanceof Integer) {
                  writableMap.putInt(key, (Integer) value);
              } else if (value instanceof Double) {
                  writableMap.putDouble(key, (Double) value);
              } else if (value instanceof String) {
                  writableMap.putString(key, (String) value);
              } else if (value instanceof JSONObject) {
                  writableMap.putMap(key, jsonToWritableMap((JSONObject) value));
              } else if (value instanceof JSONArray) {
                  writableMap.putArray(key, jsonArrayToWritableArray((JSONArray) value));
              }
          } catch (JSONException ex) {
              // Do nothing and fail silently
          }
      }

      return writableMap;
  }

  @Nullable
  public static WritableArray jsonArrayToWritableArray(JSONArray jsonArray) {
      WritableArray writableArray = new WritableNativeArray();

      if (jsonArray == null) {
          return null;
      }

      if (jsonArray.length() <= 0) {
          return null;
      }

      for (int i = 0 ; i < jsonArray.length(); i++) {
          try {
              Object value = jsonArray.get(i);
              if (value == null) {
                  writableArray.pushNull();
              } else if (value instanceof Boolean) {
                  writableArray.pushBoolean((Boolean) value);
              } else if (value instanceof Integer) {
                  writableArray.pushInt((Integer) value);
              } else if (value instanceof Double) {
                  writableArray.pushDouble((Double) value);
              } else if (value instanceof String) {
                  writableArray.pushString((String) value);
              } else if (value instanceof JSONObject) {
                  writableArray.pushMap(jsonToWritableMap((JSONObject) value));
              } else if (value instanceof JSONArray) {
                  writableArray.pushArray(jsonArrayToWritableArray((JSONArray) value));
              }
          } catch (JSONException e) {
              // Do nothing and fail silently
          }
      }

      return writableArray;
  }

}
