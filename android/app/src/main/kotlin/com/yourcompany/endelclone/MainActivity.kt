package com.yourcompany.endelclone

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall              // <-- Add these two imports
import io.flutter.plugin.common.MethodChannel.Result   // <--

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure native library is loaded and engine initialised once
        EngineHolder.ensureInit()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            // Explicitly type the parameters so Kotlin can resolve them
            .setMethodCallHandler { call: MethodCall, result: Result ->
                when (call.method) {
                    "ping" -> {
                        Log.d("AudioPlugin", "ping from Dart")
                        result.success("pong")
                    }
                    "play" -> {
                        Log.d("AudioPlugin", "play() pressed")
                        val ok = EngineHolder.instance.play()
                        result.success(ok)
                    }
                    "stop" -> {
                        val ok = EngineHolder.instance.stop()
                        result.success(ok)
                    }
                    "setConfig" -> {
                        val cfg = call.argument<String>("config")
                        Log.d("AudioPlugin", "setConfig($cfg)")
                        val ok = EngineHolder.instance.setConfig(cfg ?: "")
                        result.success(ok)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}

object EngineHolder {
    lateinit var instance: NativeBridge
    fun ensureInit() {
        if (!::instance.isInitialized) {
            instance = NativeBridge()
        }
    }
}
