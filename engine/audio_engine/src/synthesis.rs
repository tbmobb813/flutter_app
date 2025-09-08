use rand::{Rng, SeedableRng};
use rand::rngs::StdRng;
use std::f32::consts::PI;

pub struct NoiseGenerator {
    rng: StdRng,
    // For pink noise filter
    b0: f32,
    b1: f32,
    b2: f32,
    b3: f32,
    b4: f32,
    b5: f32,
    b6: f32,
}

impl NoiseGenerator {
    pub fn new() -> Self {
        Self {
            rng: StdRng::from_entropy(),
            b0: 0.0,
            b1: 0.0,
            b2: 0.0,
            b3: 0.0,
            b4: 0.0,
            b5: 0.0,
            b6: 0.0,
        }
    }

    pub fn generate_white(&mut self) -> f32 {
        self.rng.gen_range(-1.0..1.0)
    }

    pub fn generate_pink(&mut self) -> f32 {
        let white = self.generate_white();
        
        // Pink noise filter (Paul Kellett's method)
        self.b0 = 0.99886 * self.b0 + white * 0.0555179;
        self.b1 = 0.99332 * self.b1 + white * 0.0750759;
        self.b2 = 0.96900 * self.b2 + white * 0.1538520;
        self.b3 = 0.86650 * self.b3 + white * 0.3104856;
        self.b4 = 0.55000 * self.b4 + white * 0.5329522;
        self.b5 = -0.7616 * self.b5 - white * 0.0168980;
        
        let pink = self.b0 + self.b1 + self.b2 + self.b3 + self.b4 + self.b5 + self.b6 + white * 0.5362;
        self.b6 = white * 0.115926;
        
        pink * 0.11 // Scale down
    }
}

pub struct OscillatorGenerator {
    phase: f32,
    sample_rate: f32,
}

impl OscillatorGenerator {
    pub fn new(sample_rate: f32) -> Self {
        Self {
            phase: 0.0,
            sample_rate,
        }
    }

    pub fn generate_sine(&mut self, frequency: f32) -> f32 {
        let sample = (self.phase * 2.0 * PI).sin();
        self.phase += frequency / self.sample_rate;
        
        // Keep phase in range [0, 1)
        if self.phase >= 1.0 {
            self.phase -= 1.0;
        }
        
        sample
    }

    pub fn generate_square(&mut self, frequency: f32) -> f32 {
        let sample = if (self.phase * 2.0 * PI).sin() > 0.0 { 1.0 } else { -1.0 };
        self.phase += frequency / self.sample_rate;
        
        if self.phase >= 1.0 {
            self.phase -= 1.0;
        }
        
        sample
    }

    pub fn reset_phase(&mut self) {
        self.phase = 0.0;
    }
}

pub struct BinauralGenerator {
    left_osc: OscillatorGenerator,
    right_osc: OscillatorGenerator,
}

impl BinauralGenerator {
    pub fn new(sample_rate: f32) -> Self {
        Self {
            left_osc: OscillatorGenerator::new(sample_rate),
            right_osc: OscillatorGenerator::new(sample_rate),
        }
    }

    pub fn generate(&mut self, base_hz: f32, beat_hz: f32) -> (f32, f32) {
        let left_freq = base_hz - beat_hz / 2.0;
        let right_freq = base_hz + beat_hz / 2.0;
        
        let left = self.left_osc.generate_sine(left_freq);
        let right = self.right_osc.generate_sine(right_freq);
        
        (left, right)
    }
}
