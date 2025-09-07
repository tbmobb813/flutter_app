package com.yourcompany.endelclone

import android.util.Log

class NativeBridge {
    companion object {
        init {
            try {
                System.loadLibrary("audio_engine")
                Log.d("AudioPlugin", "libaudio_engine loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                Log.e("AudioPlugin", "Failed to load libaudio_engine.so: ${e.message}")
                throw e
            }
        }
    }

    // Native function declarations
    external fun jniInit(): Boolean
    external fun play(): Boolean
    external fun stop(): Boolean
    external fun setConfig(configJson: String): Boolean

    init {
        try {
            val ok = jniInit()
            Log.d("AudioPlugin", "jniInit() -> $ok")
        } catch (e: UnsatisfiedLinkError) {
            Log.e("AudioPlugin", "jniInit() failed: ${e.message}")
            throw e
        }
    }
}
