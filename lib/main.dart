import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ares.soundwave.channel.audio',
    androidNotificationChannelName: 'SOUNDWAVE',
    androidNotificationOngoing: true,
  );
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
