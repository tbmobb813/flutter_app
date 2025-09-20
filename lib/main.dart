import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add this import

import 'providers/musical_state_provider.dart'; // Add this import
import 'screens/home_screen.dart';
// import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize audio service
  // try {
  //   await AudioService.init();
  // } catch (e) {
  //   print('Audio service initialization failed: $e');
  // }

  runApp(
    ChangeNotifierProvider(
      create: (_) => MusicalStateProvider(),
      child: const EndelCloneApp(),
    ),
  );
}

class EndelCloneApp extends StatelessWidget {
  const EndelCloneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soundscapes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2DD4BF)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
