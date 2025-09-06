import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    if (running) AudioService.stop();
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
                  await _startAudioService(widget.modeName, intensity);
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