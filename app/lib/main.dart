import 'package:flutter/material.dart';

import 'features/samples/sample_collector_page.dart';

void main() {
  runApp(const ConmoneyApp());
}

class ConmoneyApp extends StatelessWidget {
  const ConmoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'conmoney',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      // P0 1단계: 알림 샘플 수집부터. 홈 화면(F4)은 다음 단계에서 붙인다.
      home: const SampleCollectorPage(),
    );
  }
}
