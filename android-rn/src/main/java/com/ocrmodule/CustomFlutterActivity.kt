package com.ocrmodule

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONException

class CustomFlutterActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "callBackResults" -> {
                        val data = call.arguments as String

                        // Invoke the callback with the list of strings
                        OcrModule.invokeCallback(data)

                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val CHANNEL = "flutter_activity"
    }
}