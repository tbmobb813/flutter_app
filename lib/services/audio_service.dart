import 'package:flutter/services.dart';
import 'dart:convert';

class AudioService {
  static const MethodChannel _channel = MethodChannel('audio_engine');
  
  static bool _initialized = false;

  /// Initialize the audio service
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      final result = await _channel.invokeMethod('ping');
      print('AudioService ping result: $result');
      _initialized = true;
    } catch (e) {
      print('Failed to initialize audio service: $e');
      rethrow;
    }
  }

  /// Start audio playback with the given preset and intensity
  static Future<void> start(String configJson) async {
    if (!_initialized) {
      await init();
    }
    
    try {
      // First set the configuration
      await _channel.invokeMethod('setConfig', {'config': configJson});
      
      // Then start playback
      final result = await _channel.invokeMethod('play');
      print('AudioService start result: $result');
    } catch (e) {
      print('Failed to start audio: $e');
      rethrow;
    }
  }

  /// Stop audio playback
  static Future<void> stop() async {
    if (!_initialized) return;
    
    try {
      final result = await _channel.invokeMethod('stop');
      print('AudioService stop result: $result');
    } catch (e) {
      print('Failed to stop audio: $e');
    }
  }

  /// Update audio parameters (like intensity)
  static Future<void> update(String updateJson) async {
    if (!_initialized) return;
    
    try {
      await _channel.invokeMethod('setConfig', {'config': updateJson});
    } catch (e) {
      print('Failed to update audio: $e');
    }
  }
}

/// Helper functions for preset loading
class PresetLoader {
  /// Load a preset by mode name from assets
  static Future<Map<String, dynamic>> loadPreset(String mode) async {
    final file = switch (mode) {
      'Relax' => 'assets/presets/relax.json',
      'Sleep' => 'assets/presets/sleep.json',
      'Calm' => 'assets/presets/calm.json',
      _ => 'assets/presets/focus.json',
    };
    
    final raw = await rootBundle.loadString(file);
    return jsonDecode(raw) as Map<String, dynamic>;
  }
  
  /// Create a config JSON for the audio engine
  static String createConfig(Map<String, dynamic> preset, double intensity) {
    return jsonEncode({
      'preset': preset,
      'intensity': intensity,
    });
  }
}