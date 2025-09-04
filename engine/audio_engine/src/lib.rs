use std::ffi::{CStr, c_char};
use std::sync::{Arc, Mutex};
use lazy_static::lazy_static;
use cpal::{Device, Stream, StreamConfig};
use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
struct AudioConfig {
    preset: Preset,
    intensity: f32,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct Preset {
    name: String,
    layers: Vec<Layer>,
    #[serde(default)]
    reverb: Option<ReverbConfig>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(tag = "type")]
enum Layer {
    #[serde(rename = "noise")]
    Noise { color: String, gain_db: f32 },
    #[serde(rename = "binaural")]
    Binaural { base_hz: f32, beat_hz: f32, mix_db: f32 },
    #[serde(rename = "pad")]
    Pad { wave: String, gain_db: f32 },
}

#[derive(Debug, Clone, Deserialize, Serialize)]
struct ReverbConfig {
    mix_db: f32,
}

struct AudioState {
    config: Option<AudioConfig>,
    intensity: f32,
    sample_rate: f32,
    channels: u32,
}

impl Default for AudioState {
    fn default() -> Self {
        Self {
            config: None,
            intensity: 0.5,
            sample_rate: 44100.0,
            channels: 2,
        }
    }
}

lazy_static! {
    static ref STATE: Arc<Mutex<AudioState>> = Arc::new(Mutex::new(AudioState::default()));
    static ref STREAM_HANDLE: Arc<Mutex<Option<Stream>>> = Arc::new(Mutex::new(None));
}

// Simple noise generators
struct NoiseGenerator {
    white_state: f32,
    pink_b0: f32,
    pink_b1: f32,
}

impl NoiseGenerator {
    fn new() -> Self {
        Self {
            white_state: 0.0,
            pink_b0: 0.0,
            pink_b1: 0.0,
        }
    }

    fn white_noise(&mut self) -> f32 {
        // Simple LCG
        self.white_state = (self.white_state * 1103515245.0 + 12345.0) % 2147483647.0;
        (self.white_state / 2147483647.0) * 2.0 - 1.0
    }

    fn pink_noise(&mut self) -> f32 {
        let white = self.white_noise();
        self.pink_b0 = 0.99886 * self.pink_b0 + white * 0.0555179;
        self.pink_b1 = 0.99332 * self.pink_b1 + white * 0.0750759;
        self.pink_b0 + self.pink_b1 + white * 0.1538520
    }

    fn brown_noise(&mut self) -> f32 {
        let white = self.white_noise();
        self.pink_b0 = (self.pink_b0 + white * 0.02).clamp(-1.0, 1.0);
        self.pink_b0
    }
}

fn db_to_amp(db: f32) -> f32 {
    10.0_f32.powf(db / 20.0)
}

#[no_mangle]
pub extern "C" fn sc_init(sample_rate: f32, channels: i32) {
    let mut state = STATE.lock().unwrap();
    state.sample_rate = sample_rate;
    state.channels = channels as u32;
}

#[no_mangle]
pub extern "C" fn sc_start(config_json: *const c_char) {
    let cstr = unsafe { CStr::from_ptr(config_json) };
    let json = cstr.to_str().unwrap_or("{}");
    
    let config: AudioConfig = match serde_json::from_str(json) {
        Ok(c) => c,
        Err(e) => {
            eprintln!("Failed to parse config: {}", e);
            return;
        }
    };

    {
        let mut state = STATE.lock().unwrap();
        state.config = Some(config.clone());
        state.intensity = config.intensity;
    }

    // Stop existing stream
    if let Some(stream) = STREAM_HANDLE.lock().unwrap().take() {
        drop(stream);
    }

    let host = cpal::default_host();
    let device = host.default_output_device().expect("No output device available");
    
    let state_clone = Arc::clone(&STATE);
    let sample_rate = STATE.lock().unwrap().sample_rate;
    let channels = STATE.lock().unwrap().channels;
    
    let config = StreamConfig {
        channels: channels as u16,
        sample_rate: cpal::SampleRate(sample_rate as u32),
        buffer_size: cpal::BufferSize::Default,
    };

    let mut noise_gen = NoiseGenerator::new();
    let mut time = 0.0f32;

    let stream = device.build_output_stream(
        &config,
        move |data: &mut [f32], _: &cpal::OutputCallbackInfo| {
            let state = state_clone.lock().unwrap();
            let intensity = state.intensity;
            let config = state.config.as_ref();
            let sr = state.sample_rate;
            let chans = state.channels as usize;

            if let Some(audio_config) = config {
                for frame in data.chunks_mut(chans) {
                    let mut out_l = 0.0f32;
                    let mut out_r = 0.0f32;

                    // Process each layer
                    for layer in &audio_config.preset.layers {
                        match layer {
                            Layer::Noise { color, gain_db } => {
                                let n = match color.as_str() {
                                    "white" => noise_gen.white_noise(),
                                    "pink" => noise_gen.pink_noise(),
                                    "brown" => noise_gen.brown_noise(),
                                    _ => noise_gen.pink_noise(),
                                };
                                let amp = db_to_amp(*gain_db) * (0.5 + 0.5 * intensity);
                                out_l += n * amp;
                                out_r += n * amp;
                            }
                            Layer::Binaural { base_hz, beat_hz, mix_db } => {
                                let left_freq = base_hz - beat_hz * 0.5;
                                let right_freq = base_hz + beat_hz * 0.5;
                                let left = (2.0 * std::f32::consts::PI * left_freq * time).sin();
                                let right = (2.0 * std::f32::consts::PI * right_freq * time).sin();
                                let amp = db_to_amp(*mix_db) * (0.8 + 0.4 * intensity);
                                out_l += left * amp;
                                out_r += right * amp;
                            }
                            Layer::Pad { wave: _, gain_db } => {
                                let freq = 110.0; // Base frequency
                                let signal = (2.0 * std::f32::consts::PI * freq * time).sin();
                                let amp = db_to_amp(*gain_db) * (0.6 + 0.6 * intensity);
                                out_l += signal * amp;
                                out_r += signal * amp;
                            }
                        }
                    }

                    // Simple soft clipping
                    frame[0] = out_l.tanh();
                    if chans > 1 {
                        frame[1] = out_r.tanh();
                    }

                    time += 1.0 / sr;
                }
            }
        },
        move |err| eprintln!("Audio error: {}", err),
        None,
    ).expect("Failed to build audio stream");

    stream.play().expect("Failed to start audio stream");
    *STREAM_HANDLE.lock().unwrap() = Some(stream);
}

#[no_mangle]
pub extern "C" fn sc_update(params_json: *const c_char) {
    let cstr = unsafe { CStr::from_ptr(params_json) };
    let json = cstr.to_str().unwrap_or("{}");
    
    if let Ok(v) = serde_json::from_str::<serde_json::Value>(json) {
        if let Some(intensity) = v.get("intensity").and_then(|x| x.as_f64()) {
            STATE.lock().unwrap().intensity = intensity as f32;
        }
    }
}

#[no_mangle]
pub extern "C" fn sc_stop() {
    if let Some(stream) = STREAM_HANDLE.lock().unwrap().take() {
        drop(stream);
    }
}