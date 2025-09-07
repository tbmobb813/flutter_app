import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../services/audio_service.dart';

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
      AudioService.stop();
    }
    super.dispose();
  }

  Future<void> _startAudioService(String modeName, double intensity) async {
    final preset = await PresetLoader.loadPreset(modeName);
    final config = PresetLoader.createConfig(preset, intensity);
    await AudioService.start(config);
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
                          await AudioService.stop();
                        } catch (e) {
                          _showError(e);
                        } finally {
                          if (mounted) setState(() => running = false);
                        }
                      }
                    },
              child: Text(running ? 'Stop' : 'Start'),
            ),

            const SizedBox(height: 24),

            // Status display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Mode: ${widget.modeName}'),
                    Text('Intensity: ${(intensity * 100).round()}%'),
                    Text('State: ${running ? 'Playing' : 'Stopped'}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
