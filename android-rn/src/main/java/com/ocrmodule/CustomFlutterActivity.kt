package com.ocrmodule

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CustomFlutterActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "callBackResults" -> {
                        val data = call.arguments as HashMap<*,*>
                        val ocrResults = data["ocrResults"] as? List<String> ?: emptyList<String>()

                        // Invoke the callback with the list of strings
                        OcrModule.invokeCallback(ocrResults)
                        result.success("")
                    }

                    else -> result.notImplemented()
                }
            }
    }

    companion object {
        private const val CHANNEL = "flutter_activity"
    }
}