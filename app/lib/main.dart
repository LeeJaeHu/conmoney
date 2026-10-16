import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/home_page.dart';
import 'services/background.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 먼저 알려주기(F7) 아침 검사. 1시간마다 깨어나 8시 이후 첫 실행에서 한 번 검사한다
  if (Platform.isAndroid) await registerBackgroundWork();
  runApp(const ProviderScope(child: ConmoneyApp()));
}

class ConmoneyApp extends StatelessWidget {
  const ConmoneyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'conmoney',
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: const HomePage(),
    );
  }
}
