package com.yourcompany.endelclone

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*
import kotlin.coroutines.coroutineContext
import kotlin.math.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "audio_engine"
    private val AUDIO_TEST_CHANNEL = "com.yourcompany.endelclone/audio_test"
    
    // Simple audio generator
    private var audioTrack: AudioTrack? = null
    private var audioJob: Job? = null
    private val sampleRate = 44100
    private var currentFrequency = 200.0f
    private var currentIntensity = 0.5f

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
                        
                        // Also start simple audio generation
                        startSimpleAudio()
                        
                        result.success(ok)
                    }
                    "stop" -> {
                        val ok = EngineHolder.instance.stop()
                        
                        // Also stop simple audio
                        stopSimpleAudio()
                        
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
    
    private fun startSimpleAudio() {
        if (audioJob?.isActive == true) return
        
        Log.d("AudioPlugin", "🎵 Starting simple audio generation")
        
        val bufferSize = AudioTrack.getMinBufferSize(
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        
        audioTrack = AudioTrack(
            AudioManager.STREAM_MUSIC,
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize * 2, // Double buffer for smoother playback
            AudioTrack.MODE_STREAM
        )
        
        audioTrack?.play()
        
        audioJob = CoroutineScope(Dispatchers.IO).launch {
            generateAudioLoop(bufferSize)
        }
    }
    
    private fun stopSimpleAudio() {
        Log.d("AudioPlugin", "🔇 Stopping simple audio")
        
        audioJob?.cancel()
        audioJob = null
        
        audioTrack?.stop()
        audioTrack?.release()
        audioTrack = null
    }
    
    private suspend fun generateAudioLoop(bufferSize: Int) {
        val buffer = ShortArray(bufferSize / 2) // 16-bit samples
        var phase = 0.0
        val baseFreq = 432.0 // Calming base frequency
        
        Log.d("AudioPlugin", "🎶 Audio generation loop started at ${baseFreq}Hz")
        
        try {
            while (coroutineContext.isActive && audioTrack != null) {
                // Calculate phase increment for current frequency
                val phaseIncrement = 2.0 * PI * baseFreq / sampleRate
                
                // Generate audio buffer
                for (i in buffer.indices) {
                    // Primary sine wave
                    val primarySine = sin(phase) * 0.4
                    
                    // Add harmonic for richer sound
                    val harmonic = sin(phase * 1.5) * 0.2 * currentIntensity
                    
                    // Add subtle pink noise for ambient feel
                    val noise = (Math.random() - 0.5) * 0.1 * currentIntensity * 0.5
                    
                    // Combine and apply intensity
                    val sample = (primarySine + harmonic + noise) * currentIntensity * 0.7
                    
                    // Convert to 16-bit PCM with clipping protection
                    buffer[i] = (sample * 32767).coerceIn(-32768.0, 32767.0).toInt().toShort()
                    
                    phase += phaseIncrement
                    if (phase >= 2.0 * PI) phase -= 2.0 * PI
                }
                
                // Write buffer to audio track
                audioTrack?.write(buffer, 0, buffer.size)
                
                // Small delay to prevent CPU overload
                delay(20)
            }
        } catch (e: Exception) {
            Log.e("AudioPlugin", "Audio generation error: ${e.message}")
        }
        
        Log.d("AudioPlugin", "🎵 Audio generation loop ended")
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
// Note: You can ignore the following error message about "libsoundcore.so" failing to load.