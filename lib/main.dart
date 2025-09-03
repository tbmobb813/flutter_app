import 'package:flutter/material.dart';
import 'screens/home_screen.dart';


void main() {
WidgetsFlutterBinding.ensureInitialized();
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