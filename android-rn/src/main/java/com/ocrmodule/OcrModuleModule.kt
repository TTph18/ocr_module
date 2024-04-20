package com.ocrmodule

import android.content.Intent
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.Callback;

class OcrModule(reactContext: ReactApplicationContext) :
  ReactContextBaseJavaModule(reactContext) {

  override fun getName(): String {
    return NAME
  }

  @ReactMethod
  fun startFlutterActivity(callback: Callback) {
    val currentActivity = reactApplicationContext.currentActivity

    val intent = Intent(currentActivity, CustomFlutterActivity::class.java)

    currentActivity?.startActivity(intent)

    setCallback(callback)
  }

  companion object {
    const val NAME = "OcrModule"
    private var callback: Callback? = null

    // Method to set the callback
    fun setCallback(cb: Callback?) {
      callback = cb
    }

    // Method to invoke the callback
    fun invokeCallback(result: String) {
      callback?.invoke(result)
    }
  }
}
