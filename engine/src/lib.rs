//! Native audio engine stub for the Endel clone.
//!
//! This crate exposes a C ABI so it can be loaded from Dart via FFI.
//! The functions parse simple JSON payloads and would normally
//! drive a DSP engine; here they simply deserialize the JSON and
//! store it in a global state.  Extend this module with real audio
//! synthesis when you're ready.

use serde::Deserialize;
use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_float, c_int};
use std::sync::Mutex;

/// Global engine state.  In a real implementation this would manage
/// audio threads, oscillators, filters, etc.  Here we just keep the
/// last configuration for debugging.
static ENGINE_STATE: Mutex<Option<EngineConfig>> = Mutex::new(None);

#[derive(Debug, Deserialize, Clone)]
struct EngineConfig {
    #[serde(default)]
    preset: serde_json::Value,
    #[serde(default)]
    intensity: Option<f32>,
}

/// Initialize the engine.  Called once on startup.
#[no_mangle]
pub extern "C" fn sc_init(sample_rate: c_float, channels: c_int) {
    // In a real engine, allocate buffers and launch audio threads.
    println!("soundcore: init sample_rate={} channels={}", sample_rate, channels);
}

/// Start a session with the given JSON config.
#[no_mangle]
pub extern "C" fn sc_start(config_json: *const c_char) {
    if config_json.is_null() {
        return;
    }
    let json_str = unsafe { CStr::from_ptr(config_json).to_string_lossy().into_owned() };
    match serde_json::from_str::<EngineConfig>(&json_str) {
        Ok(cfg) => {
            let mut state = ENGINE_STATE.lock().unwrap();
            *state = Some(cfg.clone());
            println!("soundcore: start session with config: {:?}", cfg);
        }
        Err(err) => {
            println!("soundcore: failed to parse start config: {}", err);
        }
    }
}

/// Update the current session with incremental parameters.
#[no_mangle]
pub extern "C" fn sc_update(update_json: *const c_char) {
    if update_json.is_null() {
        return;
    }
    let json_str = unsafe { CStr::from_ptr(update_json).to_string_lossy().into_owned() };
    match serde_json::from_str::<serde_json::Value>(&json_str) {
        Ok(update) => {
            let mut state = ENGINE_STATE.lock().unwrap();
            if let Some(cfg) = state.as_mut() {
                // Merge update into current state.  For simplicity just log.
                println!("soundcore: update received: {}", update);
            }
        }
        Err(err) => {
            println!("soundcore: failed to parse update: {}", err);
        }
    }
}

/// Stop the current session.
#[no_mangle]
pub extern "C" fn sc_stop() {
    let mut state = ENGINE_STATE.lock().unwrap();
    if state.is_some() {
        println!("soundcore: stop session");
        *state = None;
    }
}