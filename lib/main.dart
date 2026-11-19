import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: SoundwaveApp()));
}

class SoundwaveApp extends StatelessWidget {
  const SoundwaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOUNDWAVE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
