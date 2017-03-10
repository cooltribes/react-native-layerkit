package com.RNLayerKit.singleton;

import android.support.annotation.NonNull;
import android.support.annotation.Nullable;

import com.layer.sdk.messaging.Identity;

public final class LayerkitSingleton {

    @Nullable
    private static LayerkitSingleton instance;
    @Nullable
    private String userIdGlobal;
    @Nullable
    private String headerGlobal;
    @Nullable
    private Identity userIdentityGlobal;

    @NonNull
    public static LayerkitSingleton getInstance () {

        if ( instance == null ) {
            instance = new LayerkitSingleton();
        }

        return instance;
    }

    public static void deleteInstance () {
        instance = null;
    }

    @Nullable
    public String getUserIdGlobal() {
        return userIdGlobal;
    }

    public void setUserIdGlobal(@Nullable String userIdGlobal) {
        this.userIdGlobal = userIdGlobal;
    }

    @Nullable
    public String getHeaderGlobal() {
        return headerGlobal;
    }

    public void setHeaderGlobal(@Nullable String headerGlobal) {
        this.headerGlobal = headerGlobal;
    }

    @Nullable
    public Identity getUserIdentityGlobal() {
        return userIdentityGlobal;
    }

    public void setUserIdentityGlobal(@Nullable Identity userIdentityGlobal) {
        this.userIdentityGlobal = userIdentityGlobal;
    }
}
