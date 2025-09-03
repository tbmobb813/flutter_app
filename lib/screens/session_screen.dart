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


Map<String, dynamic> _presetFor(String mode) {
// Minimal inline preset; later load from assets/presets/*.json
switch (mode) {
case 'Relax':
return {
'name': 'Relax',
'layers': [
{'type': 'noise', 'color': 'pink', 'gain_db': -20},
{'type': 'pad', 'wave': 'sine', 'gain_db': -28}
],
'reverb': {'mix_db': -26},
};
case 'Sleep':
return {
'name': 'Sleep',
'layers': [
{'type': 'noise', 'color': 'brown', 'gain_db': -24}
],
'reverb': {'mix_db': -30},
};
default:
return {
'name': 'Focus',
'layers': [
{'type': 'noise', 'color': 'pink', 'gain_db': -18},
{'type': 'binaural', 'base_hz': 200.0, 'beat_hz': 8.5, 'mix_db': -32}
],
};
}
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
}