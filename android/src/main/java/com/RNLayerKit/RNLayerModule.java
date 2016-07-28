package com.RNLayerKit;


import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.uimanager.IllegalViewOperationException;

import com.layer.sdk.LayerClient;
import com.layer.sdk.messaging.Conversation;
import java.util.List;

import com.layer.sdk.query.Query;
import com.layer.sdk.query.SortDescriptor;
import com.layer.sdk.query.Queryable;

import com.layer.sdk.messaging.Message;

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

    Conversation[] r=new Conversation[2];

    String c="YES";

    try {
      Query query = Query.builder(Conversation.class)
              .limit(10)
              .build();

      List<Conversation> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
      
      if (results != null) {
        
        Object[] valor=new Object[]{"YES",results.get(0)};
      
          promise.resolve(valor);
      }
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  } 

  @ReactMethod
  public void getMessages(
    String convoID
    Int limit,
    Int offset,
    Promise promise) {
    try {

      Query query = Query.builder(Message.class)
              .predicate(new Predicate(Conversation.Property.CONVERSATION, Predicate
                .Operator.EQUAL_TO, this.fetchConvoWithId(convoID,layerClient)))
              .limit(10)
              .build();

      List<Message> results = layerClient.executeQuery(query, Query.ResultType.OBJECTS);
      if (results != null) {
          promise.resolve("YES",results);
      }
    } catch (IllegalViewOperationException e) {
      promise.reject(e);
    }
  }

  private Conversation fetchConvoWithId(
    String convoID,
    LayerClient client
    ) {

    Query query = Query.builder(Conversation.class)
    .predicate(new Predicate(Conversation.Property.IDENTIFIER, Predicate.Operator.EQUAL_TO, convoID))
    .build();

    List<Conversation> results = client.executeQuery(query, Query.ResultType.OBJECTS);
    if (results != null) {
      results.get(0);
    } 
    return new Conversation();
  }

}
