import 'dart:async';
import 'dart:convert';

import '../services/audio_service.dart';

/// Crossfades by ramping intensity down, switching preset, then ramping up.
/// Works even if the engine only supports { start(preset,intensity), update(intensity) }.
class Crossfader {
  static Future<void> crossfadeToPreset({
    required Map<String, dynamic> targetPreset,
    required double currentIntensity,
    Duration fade = const Duration(milliseconds: 1800),
    int steps = 12,
  }) async {
    final stepDur = Duration(
      milliseconds: (fade.inMilliseconds / steps).round(),
    );

    // fade out
    for (var i = steps; i >= 0; i--) {
      final v = (currentIntensity * i) / steps;
      await AudioService.update(jsonEncode({'intensity': v}));
      await Future<void>.delayed(stepDur);
    }

    // hard switch preset at 0 intensity
    await AudioService.stop();
    await AudioService.start(jsonEncode(targetPreset));

    // fade in
    for (var i = 0; i <= steps; i++) {
      final v = (currentIntensity * i) / steps;
      await AudioService.update(jsonEncode({'intensity': v}));
      await Future<void>.delayed(stepDur);
    }
  }
}
