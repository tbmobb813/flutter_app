import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/audio_service.dart';
import '../services/audio_test.dart'; // <- MethodChannel quick test (Android)

class SessionScreen extends StatefulWidget {
  final String modeName;
  const SessionScreen({super.key, required this.modeName});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  double intensity = 0.5;
  bool running = false;
  bool busy = false;

  @override
  void dispose() {
    if (running) {
      // Best effort stop; cannot await in dispose since dispose must be synchronous.
      // Consistent with mounted check pattern used elsewhere for safe UI updates.
      AudioService.stop();
    }
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadPreset(String mode) async {
    final file = switch (mode) {
      'Relax' => 'assets/presets/relax.json',
      'Sleep' => 'assets/presets/sleep.json',
      _ => 'assets/presets/focus.json',
    };
    final raw = await rootBundle.loadString(file);
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> _startAudioService(String modeName, double intensity) async {
    final preset = await _loadPreset(modeName);
    final config = jsonEncode({'preset': preset, 'intensity': intensity});
    AudioService.start(config);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio error: $e')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
              min: 0,
              max: 1,
              divisions: 100,
              onChanged: (v) {
                setState(() => intensity = v);
                if (running) {
                  final update = jsonEncode({'intensity': intensity});
                  AudioService.update(update);
                }
              },
            ),

            if (busy) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],

            const SizedBox(height: 16),

            // Start / Stop engine
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!running) {
                        setState(() => busy = true);
                        try {
                          await _startAudioService(widget.modeName, intensity);
                          if (!mounted) return;
                          setState(() {
                            running = true;
                          });
                        } catch (e) {
                          _showError(e);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      } else {
                        // Stop
                        try {
                          AudioService.stop();
                        } catch (e) {
                          _showError(e);
                        } finally {
                          if (mounted) setState(() => running = false);
                        }
                      }
                    },
              child: Text(running ? 'Stop' : 'Start'),
            ),

            const SizedBox(height: 12),

            // Quick Android test tone (no Rust rebuild needed)
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: (Platform.isAndroid && !busy)
                        ? () => AudioTest.playTone(
                              freq: 440,
                              ms: 1000,
                              volume: intensity,
                            )
                        : null,
                    child: const Text('Test Tone (440 Hz)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        (Platform.isAndroid && !busy) ? AudioTest.stopTone : null,
                    child: const Text('Stop Test'),
                  ),
                ),
              ],
            ),

            if (!Platform.isAndroid) ...[
              const SizedBox(height: 8),
              Text(
                'Test Tone is Android-only (uses a MethodChannel).',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
