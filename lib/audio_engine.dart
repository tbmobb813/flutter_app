import 'package:flutter/services.dart';

class AudioEngine {
  static const MethodChannel _ch = MethodChannel('audio_engine');

  static Future<String?> ping() async {
    final res = await _ch.invokeMethod<String>('ping');
    // ignore: avoid_print
    print('ping() -> $res');
    return res;
  }

  static Future<bool> play() async {
    final res = await _ch.invokeMethod<bool>('play');
    // ignore: avoid_print
    print('play() -> $res');
    return res ?? false; // <-- this is where you were seeing null before
  }

  static Future<bool> stop() async {
    final res = await _ch.invokeMethod<bool>('stop');
    // ignore: avoid_print
    print('stop() -> $res');
    return res ?? false;
  }

  static Future<bool> setConfig(String config) async {
    final res = await _ch.invokeMethod<bool>('setConfig', {'config': config});
    // ignore: avoid_print
    print('setConfig() -> $res');
    return res ?? false;
  }
}