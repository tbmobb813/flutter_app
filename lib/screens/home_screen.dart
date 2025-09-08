import 'package:flutter/material.dart';
import '../screens/session_screen.dart';

/// Home screen displaying available sound modes. This version expands the
/// original list of modes and provides a simple recommendation based on
/// the current time of day. In the morning and afternoon the app suggests
/// Focus mode; in the early evening Relax is recommended; and after 10 PM
/// Sleep is recommended. Additional modes such as Study and Recovery have
/// been added to support more contexts like learning or stress recovery.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Available sound modes. Each tuple contains the display name and an
    // associated icon. New Study and Recovery modes broaden the use cases
    // beyond the original three provided in the repository【537937622342510†L10-L14】.
    const modes = [
      ('Focus', Icons.center_focus_strong),
      ('Relax', Icons.spa),
      ('Sleep', Icons.nightlight_round),
      ('Study', Icons.menu_book),
      ('Recovery', Icons.self_improvement),
    ];

    // Compute a recommended mode based on the current hour. This is a
    // simplified "autopilot" suggesting the most appropriate mode for the
    // time of day. Morning hours (06–17) default to Focus, early evening
    // (18–21) defaults to Relax, and late night (22–05) defaults to Sleep.
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
            ),
          ],
        ),
      ),
    );
  }
}