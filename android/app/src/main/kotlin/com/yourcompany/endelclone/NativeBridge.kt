package com.yourcompany.endelclone

import android.util.Log

/**
 * Bridge between the Flutter/Dart layer and the native Rust audio engine via JNI.
 *
 * The static initializer attempts to load the native shared library.  If the library
 * cannot be loaded (for example, if it has not been built for the current ABI),
 * an UnsatisfiedLinkError will be thrown and propagated to Flutter.
 */
class NativeBridge {
    companion object {
        init {
            try {
                // Load the Rust library compiled as libaudio_engine.so.  The name here must
                // match the crate name defined in engine/audio_engine/Cargo.toml.
                System.loadLibrary("audio_engine")
                Log.d("AudioPlugin", "libaudio_engine loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                // Provide a detailed error to aid in debugging library loading failures.
                Log.e("AudioPlugin", "Failed to load libaudio_engine.so: ${e.message}")
                throw e
            }
        }
    }

    // Native function declarations.  These symbols are defined in the Rust JNI layer
    // (see engine/src/lib.rs) and exposed via the generated libaudio_engine.so.
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
