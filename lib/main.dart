import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio service
  try {
    await AudioService.init(44100.0, 2);
  } catch (e) {
    print('Audio service initialization failed: $e');
  }
  
  runApp(const EndelCloneApp());
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