package com.yourcompany.endelclone

import android.util.Log

class NativeBridge {
    companion object {
        init {
            System.loadLibrary("soundcore") // produces libsoundcore.so
            Log.d("AudioPlugin", "libsoundcore loaded")
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
