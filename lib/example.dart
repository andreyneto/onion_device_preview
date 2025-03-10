import 'package:flutter/material.dart';
import 'package:onion_device_preview/onion_device_preview.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OWTV by andreyneto',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff7147c2)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff7147c2),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: Scaffold(
        body: Center(
          child: MiyooDevice(
            // NetworkOnionTheme(name: 'win98 by kyhynngy_oyuur'),
            NetworkOnionTheme(name: 'Blueprint by Aemiii91'),
            // NetworkOnionTheme(name: 'RetroRama by TooGeekCreations'),
            precacheImages: false,
          ),
        ),
      ),
    );
  }
}
