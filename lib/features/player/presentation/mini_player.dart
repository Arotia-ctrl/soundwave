import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/track_artwork.dart';

import '../../../core/theme/app_colors.dart';
import '../data/player_providers.dart';
import 'now_playing_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ne se reconstruit que lorsque le morceau change
    final track = ref.watch(currentTrackProvider);
    if (track == null) return const SizedBox.shrink();

    final service = ref.read(playerServiceProvider);

    return Material(
      color: AppColors.elevated,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const NowPlayingScreen(),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MiniProgress(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TrackArtwork(trackId: track.id, size: 44, radius: 8),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const _MiniPlayPause(),
                  IconButton(
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      color: AppColors.text,
                    ),
                    onPressed: service.next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniProgress extends ConsumerWidget {
  const _MiniProgress();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LinearProgressIndicator(
      value: progress,
      minHeight: 2,
      color: AppColors.accent,
      backgroundColor: AppColors.surface,
    );
  }
}

class _MiniPlayPause extends ConsumerWidget {
  const _MiniPlayPause();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playingProvider).value ?? false;
    return IconButton(
      icon: Icon(
        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: AppColors.text,
        size: 30,
      ),
      onPressed: ref.read(playerServiceProvider).togglePlay,
    );
  }
}
