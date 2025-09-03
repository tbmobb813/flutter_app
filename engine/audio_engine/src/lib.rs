use std::ffi::{CStr};
let n = if color == "brown" { 0.5 * (pink_l + pink_r) } else { (pink_l + pink_r) * 0.5 };
out_l += n * amp;
out_r += n * amp;
}
Layer::Binaural { base_hz, beat_hz, mix_db } => {
let left = (2.0*std::f32::consts::PI*(base_hz - beat_hz*0.5)*t).sin();
let right= (2.0*std::f32::consts::PI*(base_hz + beat_hz*0.5)*t).sin();
let amp = db_to_amp(*mix_db) * (0.8 + 0.4*intensity);
out_l += left * amp;
out_r += right * amp;
}
Layer::Pad { wave, gain_db } => {
let f = 110.0; // base tone placeholder
let s = match wave.as_str() {
_ => (2.0*std::f32::consts::PI*f*t).sin()
};
let amp = db_to_amp(*gain_db) * (0.6 + 0.6*intensity);
out_l += s * amp;
out_r += s * amp;
}
}
}
}


// Simple soft clipper
let clip = |x: f32| (x).tanh();
frame[0] = clip(out_l);
if chans > 1 { frame[1] = clip(out_r); }


t += 1.0/sr;
}
},
move |err| { eprintln!("audio error: {err}"); },
None
).expect("Failed to build stream");


stream.play().ok();
*STREAM_HANDLE.lock() = Some(stream);
}


#[no_mangle]
pub extern "C" fn sc_update(params_json: *const c_char) {
let cstr = unsafe { CStr::from_ptr(params_json) };
let json = cstr.to_str().unwrap_or("{}");
if let Ok(v) = serde_json::from_str::<serde_json::Value>(json) {
if let Some(i) = v.get("intensity").and_then(|x| x.as_f64()) {
STATE.lock().intensity = i as f32;
}
}
}


#[no_mangle]
pub extern "C" fn sc_stop() {
if let Some(stream) = STREAM_HANDLE.lock().take() {
drop(stream);
}
}