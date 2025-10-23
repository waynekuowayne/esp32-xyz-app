import 'package:flutter/material.dart';
import 'scan_page.dart';

void main() {
  runApp(const ESP32XYZApp());
}

class ESP32XYZApp extends StatelessWidget {
  const ESP32XYZApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 XYZ 控制台',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ScanPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
