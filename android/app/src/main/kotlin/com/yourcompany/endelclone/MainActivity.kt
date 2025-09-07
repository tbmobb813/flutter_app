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
    private val AUDIO_TEST_CHANNEL = "com.yourcompany.endelclone/audio_test"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure native library is loaded and engine initialised once
        EngineHolder.ensureInit()

        // Main audio engine channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
                    else -> result.notImplemented()
                }
            }

        // Audio test channel for simple test tones
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_TEST_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: Result ->
                when (call.method) {
                    "playTone" -> {
                        Log.d("AudioTest", "playTone called")
                        // For now, just return success - actual tone generation would require audio implementation
                        result.success(null)
                    }
                    "stopTone" -> {
                        Log.d("AudioTest", "stopTone called")
                        result.success(null)
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
