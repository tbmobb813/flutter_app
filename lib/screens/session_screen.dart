import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/audio_service.dart';
import '../services/crossfade.dart';
import '../services/preset_loader.dart' as preset_loader;

/// A screen that plays back a soundscape preset for a given mode. Users can
/// adjust the intensity via a slider and start/stop the audio via a button.
/// This version extends the original implementation by loading preset
/// definitions from JSON files stored in `assets/presets/` whenever
/// possible【558463190088301†L24-L52】. If the JSON file is missing or invalid,
/// the code falls back to the inline preset definitions used in the
/// repository.

class SessionScreen extends StatefulWidget {
  final String mode; // "Focus" | "Relax" | "Sleep" | "Study" | "Recovery"
  const SessionScreen({super.key, required this.mode});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  // No instance needed, use static methods
  double _intensity = 0.5;
  bool _isPlaying = false;
  Map<String, dynamic>? _currentPreset;
  String? _currentPresetAsset;
  Timer? _rotationTimer;

  static const _rotationInterval = Duration(seconds: 30); // change if you like

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    AudioService.init(); // static method
  }

  Future<void> _restorePrefs() async {
    final sp = await SharedPreferences.getInstance();
    final keyIntensity = 'intensity_${widget.mode.toLowerCase()}';
    final saved = sp.getDouble(keyIntensity);
    if (saved != null) {
      setState(() => _intensity = saved.clamp(0.0, 1.0));
    }
  }

  Future<void> _persistIntensity() async {
    final sp = await SharedPreferences.getInstance();
    final keyIntensity = 'intensity_${widget.mode.toLowerCase()}';
    await sp.setDouble(keyIntensity, _intensity);
  }

  Future<Map<String, dynamic>> _fallbackPreset() async {
    // Your existing built-ins (shortened for brevity)
    final m = widget.mode.toLowerCase();
    if (m == 'focus') {
      return {
        "preset": {
          "name": "Focus",
          "layers": [
            {"type": "noise", "color": "pink", "gain_db": -18},
            {
              "type": "binaural",
              "base_hz": 200.0,
              "beat_hz": 8.5,
              "mix_db": -32,
            },
          ],
        },
        "intensity": _intensity,
      };
    }
    if (m == 'relax') {
      return {
        "preset": {
          "name": "Relax",
          "layers": [
            {"type": "noise", "color": "pink", "gain_db": -20},
            {"type": "pad", "wave": "sine", "gain_db": -28},
          ],
          "reverb": {"mix_db": -26},
        },
        "intensity": _intensity,
      };
    }
    if (m == 'sleep') {
      return {
        "preset": {
          "name": "Sleep",
          "layers": [
            {"type": "noise", "color": "brown", "gain_db": -24},
          ],
          "reverb": {"mix_db": -30},
        },
        "intensity": _intensity,
      };
    }
    if (m == 'study') {
      return {
        "preset": {
          "name": "Study",
          "layers": [
            {"type": "noise", "color": "brown", "gain_db": -20},
            {
              "type": "binaural",
              "base_hz": 180.0,
              "beat_hz": 5.5,
              "mix_db": -28,
            },
          ],
          "reverb": {"mix_db": -28},
        },
        "intensity": _intensity,
      };
    }
    // recovery
    return {
      "preset": {
        "name": "Recovery",
        "layers": [
          {"type": "noise", "color": "pink", "gain_db": -26},
          {"type": "pad", "wave": "sine", "gain_db": -32},
          {"type": "binaural", "base_hz": 150.0, "beat_hz": 3.5, "mix_db": -30},
        ],
        "reverb": {"mix_db": -26},
      },
      "intensity": _intensity,
    };
  }

  Future<Map<String, dynamic>> _pickInitialPreset() async {
    // Try any asset variants first (e.g. focus_1.json, focus_2.json…)
    final fromAssets = await preset_loader.PresetLoader.pickRandom(widget.mode);
    if (fromAssets != null) return fromAssets;
    // Fallback to first (if present) or built-in
    final first = await preset_loader.PresetLoader.tryLoadFirst(widget.mode);
    return first ?? _fallbackPreset();
  }

  Future<void> _start() async {
    var preset = await _pickInitialPreset();
    // Normalize asset structure: wrap with 'preset' if missing
    if (!preset.containsKey('preset') &&
        preset.containsKey('name') &&
        preset.containsKey('layers')) {
      preset = {
        'preset': {
          'name': preset['name'],
          'layers': preset['layers'],
          'reverb': preset['reverb'],
        },
        'intensity': _intensity,
        if (preset.containsKey('_assetPath'))
          '_assetPath': preset['_assetPath'],
      };
    }
    setState(() {
      _currentPreset = preset;
      _currentPresetAsset = preset['_assetPath'] as String?;
      _isPlaying = true;
    });

    final withIntensity = Map<String, dynamic>.from(preset)
      ..['intensity'] = _intensity;
    final configJson = jsonEncode(withIntensity);
    print('[DEBUG] AudioService.start config: $configJson');
    await AudioService.start(configJson);
    await AudioService.update(jsonEncode({'intensity': _intensity}));

    _rotationTimer?.cancel();
    _rotationTimer = Timer.periodic(_rotationInterval, (_) async {
      if (!_isPlaying) return;
      // Pick a different variant than the current one
      final next = await preset_loader.PresetLoader.pickRandom(
        widget.mode,
        excludeAsset: _currentPresetAsset,
      );
      if (next == null) return;

      await Crossfader.crossfadeToPreset(
        targetPreset: Map<String, dynamic>.from(next)
          ..['intensity'] = _intensity,
        currentIntensity: _intensity,
      );
      setState(() {
        _currentPreset = next;
        _currentPresetAsset = next['_assetPath'] as String?;
      });
    });
  }

  Future<void> _stop() async {
    _rotationTimer?.cancel();
    await AudioService.stop();
    setState(() => _isPlaying = false);
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    // No dispose needed for AudioService
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_currentPresetAsset != null)
              Text(
                'Variant: ${_currentPresetAsset!.split('/').last}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            if (_currentPreset != null)
              Text(
                'Preset: ${_currentPreset!['preset'] != null && _currentPreset!['preset']['name'] != null ? _currentPreset!['preset']['name'] : "Unknown"}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            Row(
              children: [
                const Text('Intensity'),
                Expanded(
                  child: Slider(
                    value: _intensity,
                    onChanged: (v) async {
                      setState(() => _intensity = v);
                      // Send full config with updated intensity
                      if (_currentPreset != null) {
                        final updatedConfig = Map<String, dynamic>.from(
                          _currentPreset!,
                        );
                        updatedConfig['intensity'] = _intensity;
                        final updateJson = jsonEncode(updatedConfig);
                        print(
                          '[DEBUG] AudioService.update config: $updateJson',
                        );
                        await AudioService.update(updateJson);
                      }
                      _persistIntensity();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isPlaying ? _stop : _start,
              child: Text(_isPlaying ? 'Stop' : 'Start'),
            ),
          ],
        ),
      ),
    );
  }
}
