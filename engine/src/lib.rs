// src/lib.rs

use std::sync::Mutex;
use once_cell::sync::Lazy;

// ----- optional logging (see section D for Cargo.toml deps) -----
#[cfg(target_os = "android")]
fn init_logger_once() {
    static DONE: Lazy<()> = Lazy::new(|| {
        android_logger::init_once(
            android_logger::Config::default().with_min_level(log::Level::Info),
        );
        log::info!("android logger ready");
    });
    Lazy::force(&DONE);
}

// ----- your engine singleton -----
struct MyEngine;
impl MyEngine {
    fn new() -> Self { MyEngine }
    fn init(&mut self) -> bool { true }             // TODO: set up Oboe stream
    fn start(&mut self) -> Result<(), ()> { Ok(()) } // TODO: requestStart()
    fn stop(&mut self) -> Result<(), ()> { Ok(()) }  // TODO: requestStop()
}

static ENGINE: Lazy<Mutex<MyEngine>> = Lazy::new(|| Mutex::new(MyEngine::new()));

// ---- JNI glue ----
use jni::objects::JClass;
use jni::sys::{jboolean, JNI_TRUE, JNI_FALSE};
use jni::JNIEnv;

// Replace this with your own JNI class path:
// Java_{PACKAGE_WITH_UNDERSCORES}_NativeBridge_jniInit
#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_jniInit(
    _env: JNIEnv,
    _cls: JClass,
) -> jboolean {
    #[cfg(target_os = "android")]
    init_logger_once();
    let ok = ENGINE.lock().unwrap().init();
    log::info!("jniInit -> {}", ok);
    if ok { JNI_TRUE } else { JNI_FALSE }
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_play(
    _env: JNIEnv,
    _cls: JClass,
) -> jboolean {
    #[cfg(target_os = "android")]
    init_logger_once();
    let ok = ENGINE.lock().unwrap().start().is_ok();
    log::info!("play -> {}", ok);
    if ok { JNI_TRUE } else { JNI_FALSE }
}

#[no_mangle]
pub extern "system" fn Java_com_yourcompany_endelclone_NativeBridge_stop(
    _env: JNIEnv,
    _cls: JClass,
) -> jboolean {
    let ok = ENGINE.lock().unwrap().stop().is_ok();
    log::info!("stop -> {}", ok);
    if ok { JNI_TRUE } else { JNI_FALSE }
}
