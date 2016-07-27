/**
 * Stub of RNLayerKit for Android.
 *
 * @providesModule RNLayerKit
 * @flow
 */
'use strict';

var warning = require('warning');
var RNLayerKit = require('react-native').NativeModules.RNLayerKit;

var RNLayerKitExport = {
  test: function() {
    warning("Not yet implemented for Android.");
  }
};

module.exports = RNLayerKitExport;
