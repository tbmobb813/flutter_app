use crate::audio_config::{AudioConfig, Layer};
use crate::effects::{db_to_linear, lerp, SimpleReverb};
use crate::synthesis::{BinauralGenerator, NoiseGenerator, OscillatorGenerator};
use oboe::{
    AudioOutputCallback, AudioOutputStream, AudioOutputStreamSafe, AudioStreamBuilder,
    DataCallbackResult, Output, PerformanceMode, SharingMode, Stereo,
};
use std::sync::{Arc, Mutex};

const SAMPLE_RATE: i32 = 48000;
const FRAMES_PER_BUFFER: i32 = 192;

pub struct AudioEngine {
    stream: Option<Box<dyn AudioOutputStreamSafe>>,
    callback: Arc<Mutex<AudioCallback>>,
}

impl AudioEngine {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let callback = Arc::new(Mutex::new(AudioCallback::new(SAMPLE_RATE as f32)));
        
        Ok(Self {
            stream: None,
            callback,
        })
    }

    pub fn start(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        if self.stream.is_some() {
            log::warn!("Audio stream already started");
            return Ok(());
        }

        let callback_clone = Arc::clone(&self.callback);
        
        let stream = AudioStreamBuilder::default()
            .set_performance_mode(PerformanceMode::LowLatency)
            .set_sharing_mode(SharingMode::Exclusive)
            .set_format::<f32>()
            .set_channel_count::<Stereo>()
            .set_sample_rate(SAMPLE_RATE)
            .set_frames_per_callback(FRAMES_PER_BUFFER)
            .set_direction::<Output>()
            .set_callback(callback_clone)
            .open_stream()?;

        self.stream = Some(Box::new(stream));
        
        log::info!("Audio engine started - Sample Rate: {}, Buffer Size: {}", SAMPLE_RATE, FRAMES_PER_BUFFER);
        Ok(())
    }

    pub fn stop(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        if let Some(mut stream) = self.stream.take() {
            stream.stop()?;
            log::info!("Audio engine stopped");
        }
        Ok(())
    }

    pub fn set_config(&self, config: AudioConfig) {
        if let Ok(mut callback) = self.callback.lock() {
            callback.set_config(config);
        }
    }

    pub fn is_playing(&self) -> bool {
        self.stream.is_some()
    }
}

struct AudioCallback {
    sample_rate: f32,
    config: AudioConfig,
    
    // Generators
    noise_gen: NoiseGenerator,
    pad_osc: OscillatorGenerator,
    binaural_gen: BinauralGenerator,
    
    // Effects
    reverb: SimpleReverb,
}

impl AudioCallback {
    fn new(sample_rate: f32) -> Self {
        Self {
            sample_rate,
            config: AudioConfig::default(),
            noise_gen: NoiseGenerator::new(),
            pad_osc: OscillatorGenerator::new(sample_rate),
            binaural_gen: BinauralGenerator::new(sample_rate),
            reverb: SimpleReverb::new(sample_rate, 50.0, 0.3, 0.2),
        }
    }

    fn set_config(&mut self, config: AudioConfig) {
        // Update reverb mix if preset has reverb settings
        if let Some(ref preset) = config.preset {
            if let Some(ref reverb_config) = preset.reverb {
                self.reverb.set_mix(reverb_config.mix_db);
            }
        }
        
        self.config = config;
        log::info!("Audio callback config updated");
    }

    fn generate_layer_audio(&mut self, layer: &Layer, intensity: f32) -> (f32, f32) {
        match layer {
            Layer::Noise { color, gain_db } => {
                let noise = match color.as_str() {
                    "pink" => self.noise_gen.generate_pink(),
                    _ => self.noise_gen.generate_white(), // Default to white
                };
                
                let gain = db_to_linear(*gain_db) * intensity;
                let sample = noise * gain;
                (sample, sample) // Mono to stereo
            }
            
            Layer::Pad { wave, gain_db } => {
                // Use a low frequency for ambient pad sounds
                let frequency = lerp(60.0, 120.0, intensity); // 60-120 Hz range
                
                let sample = match wave.as_str() {
                    "sine" => self.pad_osc.generate_sine(frequency),
                    "square" => self.pad_osc.generate_square(frequency),
                    _ => self.pad_osc.generate_sine(frequency), // Default to sine
                };
                
                let gain = db_to_linear(*gain_db) * intensity;
                let processed = sample * gain;
                (processed, processed) // Mono to stereo
            }
            
            Layer::Binaural { base_hz, beat_hz, mix_db } => {
                // Scale binaural beat frequency with intensity
                let scaled_beat = lerp(1.0, *beat_hz, intensity);
                let (left, right) = self.binaural_gen.generate(*base_hz, scaled_beat);
                
                let gain = db_to_linear(*mix_db) * intensity;
                (left * gain, right * gain)
            }
        }
    }
}

impl AudioOutputCallback for AudioCallback {
    type FrameType = (f32, Stereo);

    fn on_audio_ready(
        &mut self,
        _stream: &mut dyn AudioOutputStreamSafe,
        audio_data: &mut [f32],
    ) -> DataCallbackResult {
        let intensity = self.config.intensity.unwrap_or(0.5);
        
        // Process audio in stereo pairs
        for chunk in audio_data.chunks_mut(2) {
            let mut left_mix = 0.0;
            let mut right_mix = 0.0;
            
            // Generate and mix all layers
            if let Some(ref preset) = self.config.preset {
                let layers = preset.layers.clone(); // Clone to avoid borrowing issues
                for layer in &layers {
                    let (left, right) = self.generate_layer_audio(layer, intensity);
                    left_mix += left;
                    right_mix += right;
                }
            }
            
            // Apply reverb
            left_mix = self.reverb.process(left_mix);
            right_mix = self.reverb.process(right_mix);
            
            // Clamp to prevent clipping
            left_mix = left_mix.clamp(-1.0, 1.0);
            right_mix = right_mix.clamp(-1.0, 1.0);
            
            // Write to output buffer
            if chunk.len() >= 2 {
                chunk[0] = left_mix;
                chunk[1] = right_mix;
            } else if chunk.len() == 1 {
                chunk[0] = (left_mix + right_mix) * 0.5; // Mix to mono
            }
        }
        
        DataCallbackResult::Continue
    }
}
