import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/session_screen.dart';

/// Home screen displaying available sound modes. This version expands the
/// original list of modes and provides a simple recommendation based on
/// the current time of day. In the morning and afternoon the app suggests
/// Focus mode; in the early evening Relax is recommended; and after 10 PM
/// Sleep is recommended. Additional modes such as Study and Recovery have
/// been added to support more contexts like learning or stress recovery.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastMode;

  @override
  void initState() {
    super.initState();
    _loadLastMode();
  }

  Future<void> _loadLastMode() async {
    final sp = await SharedPreferences.getInstance();
    final last = sp.getString('last_mode');
    setState(() => _lastMode = last);
    // You can use _lastMode to preselect/highlight or auto-open SessionScreen if you like
  }

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('Focus', Icons.center_focus_strong),
      ('Relax', Icons.spa),
      ('Sleep', Icons.nightlight_round),
      ('Study', Icons.menu_book),
      ('Recovery', Icons.self_improvement),
    ];

    final hour = DateTime.now().hour;
    String recommended;
    if (hour >= 22 || hour < 6) {
      recommended = 'Sleep';
    } else if (hour >= 18) {
      recommended = 'Relax';
    } else {
      recommended = 'Focus';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Soundscapes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Suggested mode: $recommended',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (_lastMode != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'Last mode: $_lastMode',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
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
                    onTap: () async {
                      final sp = await SharedPreferences.getInstance();
                      await sp.setString('last_mode', name);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SessionScreen(mode: name),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 1,
                      color: _lastMode == name ? Colors.blue.shade50 : null,
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
            ),
          ],
        ),
      ),
    );
  }
}
