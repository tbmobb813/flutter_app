use jni::objects::{JClass, JString};
use jni::sys::{jboolean, JNI_TRUE, JNI_FALSE};
use jni::JNIEnv;
use once_cell::sync::Lazy;
use std::sync::Mutex;
use serde_json;

mod audio_config;
mod audio_engine;
mod effects;
mod synthesis;

use audio_config::AudioConfig;
use audio_engine::AudioEngine;

static ENGINE_STATE: Lazy<Mutex<EngineState>> = Lazy::new(|| {
    android_logger::init_once(
        android_logger::Config::default()
            .with_min_level(log::Level::Debug) // Change to Debug
            .with_tag("audio_engine")
    );
    Mutex::new(EngineState::new())
});

struct EngineState {
    audio_engine: Option<AudioEngine>,
    current_config: AudioConfig,
}

impl EngineState {
    fn new() -> Self {
        Self {
            audio_engine: None,
            current_config: AudioConfig::default(),
        }
    }

    fn ensure_engine(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        if self.audio_engine.is_none() {
            match AudioEngine::new() {
                Ok(engine) => {
                    log::info!("Audio engine created successfully");
                    self.audio_engine = Some(engine);
                }
                Err(e) => {
                    log::error!("Failed to create audio engine: {:?}", e);
                    return Err(e);
                }
            }
        }
        Ok(())
    }
}

// JNI exports for Kotlin/Java
#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_jniInit(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    log::info!("Native bridge initialized");
    JNI_TRUE
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_play(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    log::info!("play() called from Kotlin");
    
    let mut state = match ENGINE_STATE.lock() {
        Ok(state) => state,
        Err(e) => {
            log::error!("Failed to lock engine state: {:?}", e);
            return JNI_FALSE;
        }
    };

    // Ensure engine is created
    if let Err(e) = state.ensure_engine() {
        log::error!("Failed to ensure audio engine: {:?}", e);
        return JNI_FALSE;
    }

    // Clone config to avoid borrowing conflicts
    let current_config = state.current_config.clone();

    // Set current config and start playback
    if let Some(ref mut engine) = state.audio_engine {
        engine.set_config(current_config);
        
        match engine.start() {
            Ok(()) => {
                log::info!("Audio playback started successfully");
                JNI_TRUE
            }
            Err(e) => {
                log::error!("Failed to start audio playback: {:?}", e);
                JNI_FALSE
            }
        }
    } else {
        log::error!("Audio engine not available");
        JNI_FALSE
    }
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_stop(
    _env: JNIEnv,
    _class: JClass,
) -> jboolean {
    log::info!("stop() called from Kotlin");
    
    let mut state = match ENGINE_STATE.lock() {
        Ok(state) => state,
        Err(e) => {
            log::error!("Failed to lock engine state: {:?}", e);
            return JNI_FALSE;
        }
    };

    if let Some(ref mut engine) = state.audio_engine {
        match engine.stop() {
            Ok(()) => {
                log::info!("Audio playback stopped successfully");
                JNI_TRUE
            }
            Err(e) => {
                log::error!("Failed to stop audio playback: {:?}", e);
                JNI_FALSE
            }
        }
    } else {
        log::warn!("No audio engine to stop");
        JNI_TRUE // Not really an error
    }
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
    } else if let Some(intensity) = new_config.intensity {
        // Just intensity update
        state.current_config.intensity = Some(intensity);
    }

    // Apply to running engine if available
    if let Some(ref engine) = state.audio_engine {
        engine.set_config(state.current_config.clone());
    }

    log::debug!("Config updated successfully - intensity: {:?}", state.current_config.intensity);
    JNI_TRUE
}