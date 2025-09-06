import 'package:flutter/services.dart';

class AudioTest {
  static const _ch = MethodChannel('com.example.flutter_app/audio_test');

  static Future<void> playTone({
    double freq = 440,
    int ms = 1000,
    double volume = 0.3,
  }) => _ch.invokeMethod('playTone', {'freq': freq, 'ms': ms, 'volume': volume});

  static Future<void> stopTone() => _ch.invokeMethod('stopTone');
}
