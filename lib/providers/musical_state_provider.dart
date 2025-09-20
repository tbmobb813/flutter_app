import 'package:flutter/material.dart';

import '../models/musical_state.dart';
import '../services/procedural_audio_engine.dart';

class MusicalStateProvider extends ChangeNotifier {
  MusicalState _musical = MusicalState(
    tempo: 80,
    key: 'D',
    scale: Scale.pentatonicMinor,
    energy: 0.5,
    seed: 42,
  );

  late ProceduralAudioEngine _engine;

  MusicalStateProvider() {
    _engine = ProceduralAudioEngine(_musical);
    _engine.initialize();
  }

  MusicalState get musical => _musical;

  ProceduralAudioEngine get engine => _engine;

  void startEngine() {
    _engine.start();
  }

  void stopEngine() {
    _engine.stop();
  }

  @override
  void dispose() {
    _engine.cleanup();
    super.dispose();
  }

  void updateMusical({
    int? tempo,
    String? key,
    Scale? scale,
    double? energy,
    int? seed,
    double? binauralHz,
  }) {
    _musical = _musical.copyWith(
      tempo: tempo,
      key: key,
      scale: scale,
      energy: energy,
      seed: seed,
      binauralHz: binauralHz,
    );
    _engine.updateMusicalState(_musical);
    notifyListeners();
  }
}
