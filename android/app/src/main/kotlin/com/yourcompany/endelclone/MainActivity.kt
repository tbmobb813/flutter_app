package com.yourcompany.endelclone

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_engine"
    // Additional channel used for playing simple test tones from Dart.
    private val AUDIO_TEST_CHANNEL = "com.yourcompany.endelclone/audio_test"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure native library is loaded and engine initialised once
        EngineHolder.ensureInit()

        // Main channel handling requests for the audio engine.
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
                    // Pass a configuration string from Dart down to the native engine. Returns
                    // a boolean indicating whether the config was applied successfully.
                    "setConfig" -> {
                        val cfg = call.argument<String>("config")
                        Log.d("AudioPlugin", "setConfig($cfg)")
                        val ok = EngineHolder.instance.setConfig(cfg ?: "")
                        result.success(ok)
                    }
                    else -> result.notImplemented()
                }
            }

        // Audio test channel for simple test tones. This channel allows Dart to
        // request a short sine tone for debugging without going through the full
        // audio engine. The implementation currently just returns success; you
        // can extend it to actually play and stop tones via native code.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_TEST_CHANNEL)
            .setMethodCallHandler { call: MethodCall, result: Result ->
                when (call.method) {
                    "playTone" -> {
                        Log.d("AudioTest", "playTone called")
                        // TODO: trigger a tone in the native engine. For now, just return
                        // success so Dart can verify that the call made it here.
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
