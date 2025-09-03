import 'package:flutter/material.dart';
import '../screens/session_screen.dart';


class HomeScreen extends StatelessWidget {
const HomeScreen({super.key});


@override
Widget build(BuildContext context) {
final modes = const [
('Focus', Icons.center_focus_strong),
('Relax', Icons.spa),
('Sleep', Icons.nightlight_round),
];


return Scaffold(
appBar: AppBar(title: const Text('Soundscapes')),
body: GridView.builder(
padding: const EdgeInsets.all(16),
gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
crossAxisCount: 2,
childAspectRatio: 1.0,
crossAxisSpacing: 12,
mainAxisSpacing: 12,
),
itemCount: modes.length,
itemBuilder: (ctx, i) {
final (name, icon) = modes[i];
return InkWell(
onTap: () => Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => SessionScreen(modeName: name),
),
),
child: Card(
elevation: 1,
child: Center(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, size: 48),
const SizedBox(height: 12),
Text(name, style: const TextStyle(fontSize: 18)),
],
),
),
),
);
},
),
);
}
}