pub fn db_to_linear(db: f32) -> f32 {
    10.0_f32.powf(db / 20.0)
}

pub fn linear_to_db(linear: f32) -> f32 {
    20.0 * linear.log10()
}

pub fn clamp(value: f32, min: f32, max: f32) -> f32 {
    if value < min {
        min
    } else if value > max {
        max
    } else {
        value
    }
}

pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + (b - a) * clamp(t, 0.0, 1.0)
}

pub struct SimpleReverb {
    delay_line: Vec<f32>,
    delay_index: usize,
    feedback: f32,
    mix: f32,
}

impl SimpleReverb {
    pub fn new(sample_rate: f32, delay_ms: f32, feedback: f32, mix: f32) -> Self {
        let delay_samples = ((delay_ms / 1000.0) * sample_rate) as usize;
        Self {
            delay_line: vec![0.0; delay_samples.max(1)],
            delay_index: 0,
            feedback: feedback.clamp(0.0, 0.99),
            mix: mix.clamp(0.0, 1.0),
        }
    }

    pub fn process(&mut self, input: f32) -> f32 {
        let delayed = self.delay_line[self.delay_index];
        self.delay_line[self.delay_index] = input + delayed * self.feedback;
        
        self.delay_index = (self.delay_index + 1) % self.delay_line.len();
        
        input * (1.0 - self.mix) + delayed * self.mix
    }

    pub fn set_mix(&mut self, mix_db: f32) {
        self.mix = db_to_linear(mix_db).clamp(0.0, 1.0);
    }
}
