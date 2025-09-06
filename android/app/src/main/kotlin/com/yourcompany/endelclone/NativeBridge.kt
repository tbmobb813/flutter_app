package com.yourcompany.endelclone

import android.util.Log

class NativeBridge {
    companion object {
        init {
            System.loadLibrary("audio_engine") // produces libaudio_engine.so
            Log.d("AudioPlugin", "libaudio_engine loaded")
        }
    }

    external fun jniInit(): Boolean
    external fun play(): Boolean
    external fun stop(): Boolean

    init {
        val ok = jniInit()
        Log.d("AudioPlugin", "jniInit() -> $ok")
    }
}
