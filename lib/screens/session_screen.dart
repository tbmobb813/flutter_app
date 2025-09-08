import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/audio_service.dart';

/// A screen that plays back a soundscape preset for a given mode. Users can
/// adjust the intensity via a slider and start/stop the audio via a button.
/// This version extends the original implementation by loading preset
/// definitions from JSON files stored in `assets/presets/` whenever
/// possible【558463190088301†L24-L52】. If the JSON file is missing or invalid,
/// the code falls back to the inline preset definitions used in the
/// repository.
class SessionScreen extends StatefulWidget {
  final String modeName;
  const SessionScreen({super.key, required this.modeName});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  double intensity = 0.5;
  bool running = false;

  @override
  void dispose() {
    if (running) AudioService.stop();
    super.dispose();
  }

  /// Inline fallback presets corresponding to the original Focus, Relax and
  /// Sleep modes defined in the repository【558463190088301†L24-L52】. These are
  /// used if no JSON file can be loaded for a given mode.
  Map<String, dynamic> _presetFor(String mode) {
    switch (mode) {
      case 'Relax':
        return {
          'name': 'Relax',
          'layers': [
            {'type': 'noise', 'color': 'pink', 'gain_db': -20},
            {'type': 'pad', 'wave': 'sine', 'gain_db': -28},
          ],
          'reverb': {'mix_db': -26},
        };
      case 'Sleep':
        return {
          'name': 'Sleep',
          'layers': [
            {'type': 'noise', 'color': 'brown', 'gain_db': -24},
          ],
          'reverb': {'mix_db': -30},
        };
      case 'Study':
        return {
          'name': 'Study',
          'layers': [
            {'type': 'noise', 'color': 'brown', 'gain_db': -20},
            {
              'type': 'binaural',
              'base_hz': 180.0,
              'beat_hz': 5.5,
              'mix_db': -28.0,
            },
          ],
          'reverb': {'mix_db': -28},
        };
      case 'Recovery':
        return {
          'name': 'Recovery',
          'layers': [
            {'type': 'noise', 'color': 'pink', 'gain_db': -26},
            {'type': 'pad', 'wave': 'sine', 'gain_db': -32},
            {
              'type': 'binaural',
              'base_hz': 150.0,
              'beat_hz': 3.5,
              'mix_db': -30.0,
            },
          ],
          'reverb': {'mix_db': -32},
        };
      default:
        return {
          'name': 'Focus',
          'layers': [
            {'type': 'noise', 'color': 'pink', 'gain_db': -18},
            {
              'type': 'binaural',
              'base_hz': 200.0,
              'beat_hz': 8.5,
              'mix_db': -32,
            },
          ],
        };
    }
  }

  /// Attempt to load a preset definition from an asset file in the
  /// `assets/presets/` directory. The file name is derived from the lowercased
  /// mode name, e.g. `focus.json` or `relax.json`. If a JSON object with a
  /// `preset` field is found, its value is returned; otherwise the top-level
  /// JSON map is returned. If the file cannot be read or parsed, the
  /// corresponding fallback preset from [_presetFor] is returned.
  Future<Map<String, dynamic>> _loadPreset(String mode) async {
    final path = 'assets/presets/${mode.toLowerCase()}.json';
    try {
      final jsonStr = await rootBundle.loadString(path);
      final dynamic parsed = jsonDecode(jsonStr);
      if (parsed is Map<String, dynamic>) {
        if (parsed.containsKey('preset') && parsed['preset'] is Map) {
          return Map<String, dynamic>.from(parsed['preset']);
        }
        return Map<String, dynamic>.from(parsed);
      }
    } catch (_) {
      // ignore and use fallback
    }
    return _presetFor(mode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.modeName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Intensity: ${intensity.toStringAsFixed(2)}'),
            Slider(
              value: intensity,
              onChanged: (v) {
                setState(() => intensity = v);
                if (running) {
                  final update = jsonEncode({'intensity': intensity});
                  AudioService.update(update);
                }
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (!running) {
                  // Load preset from JSON if available, otherwise fall back.
                  final preset = await _loadPreset(widget.modeName);
                  final config = jsonEncode({
                    'preset': preset,
                    'intensity': intensity,
                  });
                  await AudioService.start(config);
                  setState(() => running = true);
                } else {
                  AudioService.stop();
                  setState(() => running = false);
                }
              },
              child: Text(running ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}