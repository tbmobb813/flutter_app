use crate::audio_config::{AudioConfig, Layer};

pub struct SimpleAudioEngine {
    config: AudioConfig,
    is_playing: bool,
}

impl SimpleAudioEngine {
    pub fn new() -> Result<Self, Box<dyn std::error::Error>> {
        Ok(Self {
            config: AudioConfig::default(),
            is_playing: false,
        })
    }

    pub fn start(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        self.is_playing = true;
        log::info!("🎵 Audio engine started - Enhanced logging mode");
        
        // Log the current configuration in detail
        let intensity = self.config.intensity.unwrap_or(0.5);
        log::info!("🎛️ Current intensity: {:.2}", intensity);
        
        if let Some(ref preset) = self.config.preset {
            log::info!("🎶 Playing preset: '{}' with {} layers", preset.name, preset.layers.len());
            
            for (i, layer) in preset.layers.iter().enumerate() {
                match layer {
                    Layer::Noise { color, gain_db } => {
                        let effective_gain = gain_db + (intensity - 0.5) * 6.0; // ±3dB range
                        log::info!("  🔊 Layer {}: {} noise at {:.1}dB (intensity adjusted from {}dB)", 
                                  i + 1, color, effective_gain, gain_db);
                    }
                    Layer::Pad { wave, gain_db } => {
                        let effective_gain = gain_db + (intensity - 0.5) * 6.0;
                        let frequency = 60.0 + intensity * 60.0; // 60-120 Hz
                        log::info!("  🎹 Layer {}: {} pad at {:.1}Hz, {:.1}dB (intensity adjusted)", 
                                  i + 1, wave, frequency, effective_gain);
                    }
                    Layer::Binaural { base_hz, beat_hz, mix_db } => {
                        let effective_beat = 1.0 + intensity * (beat_hz - 1.0);
                        let effective_gain = mix_db + (intensity - 0.5) * 6.0;
                        log::info!("  🧠 Layer {}: binaural {:.1}Hz ±{:.1}Hz at {:.1}dB (beats scaled by intensity)", 
                                  i + 1, base_hz, effective_beat, effective_gain);
                    }
                }
            }
            
            if let Some(ref reverb) = preset.reverb {
                log::info!("  🌊 Reverb: {:.1}dB mix", reverb.mix_db);
            }
        } else {
            log::info!("🔇 No preset loaded - would play silence");
        }
        
        Ok(())
    }

    pub fn stop(&mut self) -> Result<(), Box<dyn std::error::Error>> {
        self.is_playing = false;
        log::info!("🔇 Audio engine stopped");
        Ok(())
    }

    pub fn set_config(&mut self, config: AudioConfig) {
        // Detect what type of update this is
        if config.preset.is_some() {
            log::info!("🎛️ Full preset configuration update received");
        } else if config.intensity.is_some() {
            log::debug!("📊 Intensity update: {:.3}", config.intensity.unwrap());
        }
        
        // Update configuration
        if config.preset.is_some() {
            self.config = config;
        } else if let Some(intensity) = config.intensity {
            self.config.intensity = Some(intensity);
        }
        
        // If playing, show real-time update
        if self.is_playing && config.intensity.is_some() {
            let intensity = config.intensity.unwrap();
            if intensity % 0.1 < 0.01 || intensity % 0.1 > 0.09 { // Log every 0.1 change
                log::info!("🔄 Real-time intensity: {:.1} ({}%)", intensity, (intensity * 100.0) as i32);
            }
        }
    }

    pub fn is_playing(&self) -> bool {
        self.is_playing
    }
}
