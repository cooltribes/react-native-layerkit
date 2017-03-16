package com.RNLayerKit.utils;

import android.content.Context;
import android.content.SharedPreferences;

import com.layer.sdk.LayerClient;

/**
 * Class with utils functions to layer
 * Created by eduardo.dleon on 3/16/17.
 */

public final class LayerUtils {

    private static final String NAME = LayerUtils.class.getSimpleName();
    private static final String APP_ID = "appId";

    public static void setAppId(Context context, String appId) {

        SharedPreferences sharedPreferences = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();
        editor.putString(APP_ID, appId);
        editor.apply();

    }

    private static String getAppId(Context context) {

        SharedPreferences sharedPreferences = context.getSharedPreferences(NAME, Context.MODE_PRIVATE);

        return sharedPreferences.getString(APP_ID, null);
    }

    public static LayerClient getLayerClient(Context context) {

        return LayerClient.newInstance(context, getAppId(context));
    }

}
