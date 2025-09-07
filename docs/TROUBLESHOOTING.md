# Troubleshooting Guide - Library Loading Issue

## 🚨 **Current Issue**

**Error Message:**

```
I/flutter (31420): Failed to initialize audio engine: Invalid argument(s): 
Failed to load dynamic library 'libsoundcore.so': dlopen failed: library "libsoundcore.so" not found
```

**Problem**: App is trying to load `libsoundcore.so` but we built `libaudio_engine.so`

---

## 🔍 **Diagnostic Steps**

### **Step 1: Verify Library Files**

```bash
# Check if our library exists
ls -la android/app/src/main/jniLibs/arm64-v8a/
# Should show: libaudio_engine.so (665KB)

# Check for any old library files
find . -name "*soundcore*" -type f
# Should return: No results (or only in docs/scripts)
```

### **Step 2: Verify Code References**

```bash
# Search for any hardcoded library names
grep -r "soundcore" lib/ android/
grep -r "libsoundcore" lib/ android/
grep -r "DynamicLibrary" lib/
```

### **Step 3: Check Build Configuration**

```bash
# Verify Rust library name
grep "name.*=" engine/audio_engine/Cargo.toml
# Should show: name = "audio_engine"

# Check Android library loading
grep "loadLibrary" android/app/src/main/kotlin/com/yourcompany/endelclone/NativeBridge.kt
# Should show: System.loadLibrary("audio_engine")
```

---

## 🛠️ **Resolution Strategies**

### **Strategy 1: Complete Clean Build**

```bash
# 1. Clean all caches
flutter clean
cd engine/audio_engine && cargo clean && cd ../..

# 2. Remove old build artifacts
rm -rf android/app/src/main/jniLibs/
rm -rf build/
rm -rf engine/target/

# 3. Rebuild from scratch
cd engine/audio_engine
cargo ndk -o ../../android/app/src/main/jniLibs build --release
cd ../..
flutter run
```

### **Strategy 2: Verify Library Name Consistency**

Check these files for library name references:

**File: `engine/audio_engine/Cargo.toml`**

```toml
[lib]
name = "audio_engine"  # ← Must match loadLibrary() call
crate-type = ["cdylib"]
```

**File: `android/app/src/main/kotlin/.../NativeBridge.kt`**

```kotlin
init { 
    System.loadLibrary("audio_engine")  # ← Must match Cargo.toml name
}
```

### **Strategy 3: Debug Method Channel Directly**

```dart
// Add this test in your debug interface
Future<void> testDirectChannel() async {
    try {
        const channel = MethodChannel('audio_engine');
        final result = await channel.invokeMethod('ping');
        print('Direct channel test: $result');
    } catch (e) {
        print('Direct channel error: $e');
        // This will show the exact error source
    }
}
```

---

## 🔎 **Advanced Debugging**

### **Check Android Logs**

```bash
# Filter for relevant log messages
adb logcat | grep -E "(soundcore|audio_engine|JNI|UnsatisfiedLinkError)"

# Look for library loading messages
adb logcat | grep -E "(Loading|dlopen|loadLibrary)"
```

### **Verify JNI Exports**

```bash
# Check what symbols are exported from our library
nm -D android/app/src/main/jniLibs/arm64-v8a/libaudio_engine.so | grep Java

# Should show something like:
# Java_com_yourcompany_endelclone_NativeBridge_jniInit
# Java_com_yourcompany_endelclone_NativeBridge_play
# Java_com_yourcompany_endelclone_NativeBridge_stop
# Java_com_yourcompany_endelclone_NativeBridge_setConfig
```

### **Inspect Flutter Dependencies**

```bash
# Check if any dependency is trying to load the old library
flutter pub deps --style=compact | grep -i audio
flutter pub deps --style=compact | grep -i ffi

# Verify no old dependencies remain
grep -r "libsoundcore" ~/.pub-cache/ 2>/dev/null || echo "No cached references found"
```

---

## 🚑 **Emergency Fixes**

### **Fix 1: Force Library Name Alignment**

If the issue persists, temporarily rename the library to match what the app expects:

```bash
# Copy the library with the expected name
cp android/app/src/main/jniLibs/arm64-v8a/libaudio_engine.so \
   android/app/src/main/jniLibs/arm64-v8a/libsoundcore.so

# Test if this resolves the loading issue
flutter run
```

⚠️ **This is a temporary fix only - find the root cause**

### **Fix 2: Create Symbolic Link**

```bash
# Create a symbolic link with the expected name
cd android/app/src/main/jniLibs/arm64-v8a/
ln -s libaudio_engine.so libsoundcore.so
cd ../../../../..
```

### **Fix 3: Update All References**

If the app really expects `libsoundcore.so`, update our build:

**Change `engine/audio_engine/Cargo.toml`:**

```toml
[lib]
name = "soundcore"  # Match what app expects
crate-type = ["cdylib"]
```

**Change `NativeBridge.kt`:**

```kotlin
System.loadLibrary("soundcore")  # Match Cargo.toml name
```

**Rebuild:**

```bash
cargo ndk build --release  # Will create libsoundcore.so
```

---

## 🧪 **Testing Methodology**

### **Test 1: Isolated Method Channel**

Create a minimal test to isolate the issue:

```dart
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
        const channel = MethodChannel('audio_engine');
        print('Testing method channel...');
        
        final result = await channel.invokeMethod('ping');
        print('SUCCESS: $result');
    } catch (e) {
        print('ERROR: $e');
        print('Error type: ${e.runtimeType}');
    }
}
```

### **Test 2: Progressive Loading**

Test each component in isolation:

1. **Library Loading Only**: Just load the library without calling functions
2. **Simple JNI Call**: Call a basic function that doesn't use complex types
3. **Full Integration**: Test complete audio pipeline

### **Test 3: Platform-Specific Debug**

```kotlin
// Add to NativeBridge.kt for detailed logging
init {
    try {
        Log.d("AudioEngine", "Attempting to load library...")
        System.loadLibrary("audio_engine")
        Log.d("AudioEngine", "Library loaded successfully")
        
        // Test immediate JNI call
        val result = jniInit()
        Log.d("AudioEngine", "JNI init result: $result")
    } catch (e: UnsatisfiedLinkError) {
        Log.e("AudioEngine", "Library loading failed", e)
        throw e
    }
}
```

---

## 📋 **Resolution Checklist**

- [ ] Verified `libaudio_engine.so` exists and has correct size (~665KB)
- [ ] Confirmed no references to `libsoundcore` in current code
- [ ] Cleaned all build caches (Flutter + Cargo)
- [ ] Rebuilt library with `cargo ndk build --release`
- [ ] Tested method channel with debug interface
- [ ] Checked Android logs for specific error details
- [ ] Verified JNI function exports are present
- [ ] Confirmed library name consistency across all files
- [ ] Tested with minimal reproduction case
- [ ] Isolated the exact source of the error message

---

## 🎯 **Expected Resolution**

Once resolved, you should see:

```
I/flutter: AudioService ping result: Audio engine loaded successfully
I/flutter: AudioService start result: true
```

And the debug test interface should show:

- ✅ Ping test: "Audio engine loaded successfully"
- ✅ Play test: Success
- ✅ Stop test: Success

---

**Last Updated**: September 7, 2025  
**Status**: Issue analysis complete, ready for resolution testing
