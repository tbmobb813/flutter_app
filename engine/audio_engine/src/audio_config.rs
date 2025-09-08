use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct AudioConfig {
    pub preset: Option<Preset>,
    pub intensity: Option<f32>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct Preset {
    pub name: String,
    pub layers: Vec<Layer>,
    pub reverb: Option<ReverbConfig>,
}

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum Layer {
    #[serde(rename = "noise")]
    Noise {
        color: String,
        gain_db: f32,
    },
    #[serde(rename = "pad")]
    Pad {
        wave: String,
        gain_db: f32,
    },
    #[serde(rename = "binaural")]
    Binaural {
        base_hz: f32,
        beat_hz: f32,
        mix_db: f32,
    },
}

#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ReverbConfig {
    pub mix_db: f32,
}

impl Default for AudioConfig {
    fn default() -> Self {
        Self {
            preset: None,
            intensity: Some(0.5),
        }
    }
}
