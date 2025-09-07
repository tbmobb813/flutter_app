import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioEngineTest extends StatefulWidget {
  const AudioEngineTest({super.key});

  @override
  State<AudioEngineTest> createState() => _AudioEngineTestState();
}

class _AudioEngineTestState extends State<AudioEngineTest> {
  static const MethodChannel _channel = MethodChannel('audio_engine');
  String _status = 'Not tested';

  Future<void> _testPing() async {
    try {
      setState(() => _status = 'Testing...');
      final result = await _channel.invokeMethod('ping');
      setState(() => _status = 'Success: $result');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _testPlay() async {
    try {
      setState(() => _status = 'Testing play...');
      final result = await _channel.invokeMethod('play');
      setState(() => _status = 'Play result: $result');
    } catch (e) {
      setState(() => _status = 'Play error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Audio Engine Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Status: $_status'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _testPing,
              child: const Text('Test Ping'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _testPlay,
              child: const Text('Test Play'),
            ),
          ],
        ),
      ),
    );
  }
}
