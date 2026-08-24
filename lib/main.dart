import 'package:flutter/material.dart';
import 'screens/public/public_beranda.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Retribusi Sampah Kudus',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Set to PublicBeranda as default for now
      home: const PublicBeranda(),
    );
  }
}
