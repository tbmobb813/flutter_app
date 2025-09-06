package com.yourcompany.endelclone

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_engine"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Ensure native library is loaded and engine initialized once
        EngineHolder.ensureInit()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "ping" -> {
                        Log.d("AudioPlugin", "ping from Dart")
                        result.success("pong")
                    }
                    "play" -> {
                        Log.d("AudioPlugin", "play() pressed")
                        val ok = EngineHolder.instance.play()
                        result.success(ok) // <<-- THIS prevents Dart from seeing null
                    }
                    "stop" -> {
                        val ok = EngineHolder.instance.stop()
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
