import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../shared/models/track.dart';
import 'player_service.dart';

class QueueNotifier extends Notifier<List<Track>> {
  @override
  List<Track> build() => const [];

  void set(List<Track> tracks) => state = tracks;
}

final queueProvider = NotifierProvider<QueueNotifier, List<Track>>(
  QueueNotifier.new,
);

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService(
    ref.watch(audioPlayerProvider),
    (tracks) => ref.read(queueProvider.notifier).set(tracks),
  );
});

final currentIndexProvider = StreamProvider<int?>(
  (ref) => ref.watch(audioPlayerProvider).currentIndexStream,
);

final playingProvider = StreamProvider<bool>(
  (ref) => ref.watch(audioPlayerProvider).playingStream,
);

final positionProvider = StreamProvider<Duration>(
  (ref) => ref.watch(audioPlayerProvider).positionStream,
);

final durationProvider = StreamProvider<Duration?>(
  (ref) => ref.watch(audioPlayerProvider).durationStream,
);

final shuffleProvider = StreamProvider<bool>(
  (ref) => ref.watch(audioPlayerProvider).shuffleModeEnabledStream,
);

final loopModeProvider = StreamProvider<LoopMode>(
  (ref) => ref.watch(audioPlayerProvider).loopModeStream,
);

/// Morceau en cours, ou null si rien n'a été lancé.
final currentTrackProvider = Provider<Track?>((ref) {
  final queue = ref.watch(queueProvider);
  if (queue.isEmpty) return null;
  final index = ref.watch(currentIndexProvider).value;
  if (index == null || index < 0 || index >= queue.length) return null;
  return queue[index];
});
