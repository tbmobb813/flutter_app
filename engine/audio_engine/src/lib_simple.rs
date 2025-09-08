use jni::objects::{JClass, JString};
use jni::sys::{jboolean, JNI_TRUE, JNI_FALSE};
use jni::JNIEnv;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use serde_json;

mod audio_config;

use audio_config::AudioConfig;

static ENGINE_STATE: Lazy<Mutex<EngineState>> = Lazy::new(|| {
    android_logger::init_once(
        android_logger::Config::default().with_max_level(log::LevelFilter::Debug),
    );
    Mutex::new(EngineState::new())
});

struct EngineState {
    is_playing: bool,
    current_config: AudioConfig,
}

impl EngineState {
    fn new() -> Self {
        Self {
            is_playing: false,
            current_config: AudioConfig::default(),
        }
    }
}

// JNI exports for Kotlin/Java
#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_jniInit(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    log::info!("Native bridge initialized - Simple Audio Engine v1.0");
    JNI_TRUE
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_play(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    log::info!("play() called - Starting simple audio simulation");
    
    let mut state = match ENGINE_STATE.lock() {
        Ok(state) => state,
        Err(e) => {
            log::error!("Failed to lock engine state: {:?}", e);
            return JNI_FALSE;
        }
    };

    state.is_playing = true;
    
    // Simulate audio processing
    log::info!("🎵 Audio engine simulating playback with config: intensity={:?}", 
               state.current_config.intensity);
    
    if let Some(ref preset) = state.current_config.preset {
        log::info!("🎶 Playing preset: {} with {} layers", 
                   preset.name, preset.layers.len());
        
        for (i, layer) in preset.layers.iter().enumerate() {
            match layer {
                audio_config::Layer::Noise { color, gain_db } => {
                    log::info!("  Layer {}: {} noise at {}dB", i + 1, color, gain_db);
                }
                audio_config::Layer::Pad { wave, gain_db } => {
                    log::info!("  Layer {}: {} pad at {}dB", i + 1, wave, gain_db);
                }
                audio_config::Layer::Binaural { base_hz, beat_hz, mix_db } => {
                    log::info!("  Layer {}: binaural {}Hz ±{}Hz at {}dB", 
                               i + 1, base_hz, beat_hz, mix_db);
                }
            }
        }
    } else {
        log::info!("🔇 No preset loaded, playing silence");
    }
    
    JNI_TRUE
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_stop(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    log::info!("stop() called - Stopping audio simulation");
    
    let mut state = match ENGINE_STATE.lock() {
        Ok(state) => state,
        Err(e) => {
            log::error!("Failed to lock engine state: {:?}", e);
            return JNI_FALSE;
        }
    };

    state.is_playing = false;
    log::info!("🔇 Audio engine stopped");
    JNI_TRUE
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_setConfig(
    mut env: JNIEnv,
    _class: JClass,
    config_json: JString,
) -> jboolean {
    let config_str: String = match env.get_string(&config_json) {
        Ok(java_str) => java_str.into(),
        Err(e) => {
            log::error!("Failed to get config string: {:?}", e);
            return JNI_FALSE;
        }
    };
    
    log::info!("setConfig called with: {}", config_str);
    
    // Parse JSON config
    let new_config: AudioConfig = match serde_json::from_str(&config_str) {
        Ok(config) => config,
        Err(e) => {
            log::error!("Failed to parse config JSON: {:?}", e);
            return JNI_FALSE;
        }
    };

    let mut state = match ENGINE_STATE.lock() {
        Ok(state) => state,
        Err(e) => {
            log::error!("Failed to lock engine state: {:?}", e);
            return JNI_FALSE;
        }
    };

    // Update config
    if new_config.preset.is_some() {
        // Full config update with preset
        state.current_config = new_config.clone();
        log::info!("🎛️ Updated full audio config with new preset");
    } else if let Some(intensity) = new_config.intensity {
        // Just intensity update
        state.current_config.intensity = Some(intensity);
        log::debug!("📊 Updated intensity to: {:.2}", intensity);
    }

    // If currently playing, log the change
    if state.is_playing {
        log::info!("🔄 Real-time config update applied while playing");
    }

    JNI_TRUE
}
