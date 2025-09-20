import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_sound/flutter_sound.dart';

import '../models/musical_state.dart';

class ProceduralAudioEngine {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  StreamSubscription? _audioStream;
  bool _isPlaying = false;
  MusicalState _musical;

  ProceduralAudioEngine(this._musical);

  Future<void> initialize() async {
    await _player.openAudioSession();
  }

  Future<void> start() async {
    if (_isPlaying) return;
    _isPlaying = true;
    _audioStream = _player.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: 44100,
    );
    _generateAudio();
  }

  void stop() {
    _isPlaying = false;
    _audioStream?.cancel();
    _player.stopPlayer();
  }

  void cleanup() {
    stop();
    _player.closeAudioSession();
  }

  void updateMusicalState(MusicalState state) {
    _musical = state;
  }

  // Example: Generate a simple evolving pad sound
  void _generateAudio() async {
    const sampleRate = 44100;
    const bufferSize = 1024;
    final rng = Random(_musical.seed);
    double phase = 0.0;
    double freq = 220.0 + (_musical.energy * 220.0);

    // Chord notes (simple triad)
    List<double> chordFreqs = [
      freq,
      freq * pow(2, 4 / 12), // major third
      freq * pow(2, 7 / 12), // perfect fifth
    ];

    while (_isPlaying) {
      final buffer = Int16List(bufferSize);
      for (int i = 0; i < bufferSize; i++) {
        double t = phase + i / sampleRate;
        // Pad: sum of detuned sines
        double pad =
            chordFreqs.map((f) => sin(2 * pi * f * t)).reduce((a, b) => a + b) /
            chordFreqs.length;
        // Motif: short random notes
        double motif = 0.0;
        if (rng.nextDouble() < 0.01 * _musical.energy) {
          double motifFreq = freq * pow(2, rng.nextInt(12) / 12.0);
          motif += sin(2 * pi * motifFreq * t) * 0.3;
        }
        buffer[i] = ((pad * 0.5 + motif) * 32767).toInt();
      }
      phase += bufferSize / sampleRate;
      await _player.feedFromStream(Uint8List.view(buffer.buffer));
      await Future.delayed(
        Duration(milliseconds: (bufferSize / sampleRate * 1000).round()),
      );
    }
  }
}
