import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'core/navigation/main_shell.dart';
import 'core/theme/app_theme.dart';
import 'features/analyzer/presentation/analysis_controller.dart';
import 'features/library/data/user_data_providers.dart';
import 'features/library/presentation/library_controller.dart';
import 'features/player/data/playback_persistence.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ares.soundwave.channel.audio',
    androidNotificationChannelName: 'SOUNDWAVE',
    androidNotificationOngoing: true,
  );
  runApp(const ProviderScope(child: SoundwaveApp()));
}

class SoundwaveApp extends ConsumerWidget {
  const SoundwaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Services d'arrière-plan : historique, rescan, reprise, analyse auto
    ref.watch(historyRecorderProvider);
    ref.watch(libraryAutoRefreshProvider);
    ref.watch(playbackPersistenceProvider);
    ref.watch(autoAnalysisProvider);

    return MaterialApp(
      title: 'SOUNDWAVE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}
