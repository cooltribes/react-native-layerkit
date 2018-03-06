package com.RNLayerKit.listeners;

import com.RNLayerKit.react.RNLayerModule;
import com.RNLayerKit.utils.ConverterHelper;
import com.layer.sdk.changes.LayerChangeEvent;
import com.layer.sdk.listeners.LayerChangeEventListener;
import com.facebook.react.bridge.WritableMap;

import com.layer.sdk.changes.LayerChange;
import java.util.List;
import com.facebook.react.bridge.Arguments;
import com.layer.sdk.messaging.LayerObject;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableNativeArray;
import com.facebook.react.bridge.WritableNativeMap;

public class ChangeEventListener implements LayerChangeEventListener {

    private RNLayerModule mRNLayerModule;

    public ChangeEventListener(RNLayerModule mRNLayerModule) {
        this.mRNLayerModule = mRNLayerModule;
    }

    @Override
    public void onChangeEvent(LayerChangeEvent event) {

    	List<LayerChange> changes = event.getChanges();

    	WritableMap params = Arguments.createMap();

    	WritableArray writableArray = new WritableNativeArray();

    	for (int i = 0; i < changes.size(); i++) {

            LayerChange change = changes.get(i);

	        WritableMap writableMap = new WritableNativeMap();

            switch (change.getObjectType()) {

            	case MESSAGE:

                    // Update
            		if(change.getChangeType() == LayerChange.Type.UPDATE) {
            			
            			switch (change.getAttributeName()) {

            				case "recipientStatus":
            				case "isDeleted":

		            			writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
            					break;
            			}
	            	}
                    break;

                case CONVERSATION:

                    // Update
	            	if(change.getChangeType() == LayerChange.Type.UPDATE) {
	            		
	            		switch (change.getAttributeName()) {

            				case "lastMessage":
            				case "totalUnreadMessageCount":
            				case "metadata":
            				case "participants":

								writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
            					params.putInt("badge", mRNLayerModule.getMessagesCount());
            					break;
            			}
	            	}

	            	// Create
	            	if(change.getChangeType() == LayerChange.Type.INSERT) {
	            		writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
	            	}
                    break;

                case IDENTITY:

                    writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);
                    break;

                case MESSAGE_PART:
                    
                    writableMap = ConverterHelper.convertChangesToArray(change, mRNLayerModule);                    
                    break;
            }

            writableArray.pushMap(writableMap);
           
        }

        params.putString("source", "LayerClient");
        params.putString("type", "objectsDidChange");
        params.putArray("data", writableArray);

        // WritableMap params = ConverterHelper.convertChangesToArray(event, mRNLayerModule);

        // Send Event React
        mRNLayerModule.sendEvent(mRNLayerModule.getReactContext(), "LayerEvent", params);

    }
}