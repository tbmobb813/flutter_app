import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioEngineTest extends StatefulWidget {
  const AudioEngineTest({super.key});

  @override
  State<AudioEngineTest> createState() => _AudioEngineTestState();
}

class _AudioEngineTestState extends State<AudioEngineTest> {
  static const MethodChannel _channel = MethodChannel('audio_engine');
  String _status = 'Ready to test';
  bool _testing = false;

  Future<void> _testPing() async {
    if (_testing) return;
    
    setState(() {
      _testing = true;
      _status = 'Testing ping...';
    });
    
    try {
      print('🧪 Testing method channel ping...');
      final result = await _channel.invokeMethod('ping');
      print('✅ Ping successful: $result');
      setState(() => _status = '✅ SUCCESS: $result');
    } catch (e) {
      print('❌ Ping failed: $e');
      setState(() => _status = '❌ ERROR: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _testPlay() async {
    if (_testing) return;
    
    setState(() {
      _testing = true;
      _status = 'Testing play...';
    });
    
    try {
      print('🧪 Testing audio engine play...');
      final result = await _channel.invokeMethod('play');
      print('✅ Play successful: $result');
      setState(() => _status = '✅ PLAY SUCCESS: $result');
    } catch (e) {
      print('❌ Play failed: $e');
      setState(() => _status = '❌ PLAY ERROR: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  Future<void> _testStop() async {
    if (_testing) return;
    
    setState(() {
      _testing = true;
      _status = 'Testing stop...';
    });
    
    try {
      print('🧪 Testing audio engine stop...');
      final result = await _channel.invokeMethod('stop');
      print('✅ Stop successful: $result');
      setState(() => _status = '✅ STOP SUCCESS: $result');
    } catch (e) {
      print('❌ Stop failed: $e');
      setState(() => _status = '❌ STOP ERROR: $e');
    } finally {
      setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Audio Engine Debug'),
        backgroundColor: Colors.orange.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Debug Status', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(_status, style: Theme.of(context).textTheme.bodyLarge),
                    if (_testing) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text('Test Method Channel Communication:', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _testing ? null : _testPing,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('1. Test Ping'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tests if Flutter can communicate with Android via Method Channel',
              style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 20),
            
            const Text('Test Audio Engine Functions:', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _testing ? null : _testPlay,
              icon: const Icon(Icons.play_arrow),
              label: const Text('2. Test Play'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade100,
                foregroundColor: Colors.green.shade700,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _testing ? null : _testStop,
              icon: const Icon(Icons.stop),
              label: const Text('3. Test Stop'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Tests if the Rust audio engine can be controlled via JNI',
              style: TextStyle(color: Colors.grey)),
              
            const Spacer(),
            const Card(
              color: Colors.blue,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  '💡 Tip: Check the console logs for detailed debug output',
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
