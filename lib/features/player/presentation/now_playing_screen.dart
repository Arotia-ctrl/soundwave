import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../data/player_providers.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final playing = ref.watch(playingProvider).value ?? false;
    final shuffle = ref.watch(shuffleProvider).value ?? false;
    final loop = ref.watch(loopModeProvider).value ?? LoopMode.off;
    final service = ref.read(playerServiceProvider);

    if (track == null) {
      return const Scaffold(body: Center(child: Text('Rien en lecture')));
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('En cours de lecture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music_rounded),
            tooltip: "File d'attente",
            onPressed: () => _showQueue(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            QueryArtworkWidget(
              id: track.id,
              type: ArtworkType.AUDIO,
              size: 800,
              artworkWidth: 300,
              artworkHeight: 300,
              artworkFit: BoxFit.cover,
              artworkBorder: BorderRadius.circular(20),
              nullArtworkWidget: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: AppColors.elevated,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 96,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              track.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              track.artist,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const _SeekBar(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.shuffle_rounded,
                    color: shuffle ? AppColors.accent : AppColors.textMuted,
                  ),
                  onPressed: () => service.setShuffle(!shuffle),
                ),
                IconButton(
                  iconSize: 38,
                  icon: const Icon(
                    Icons.skip_previous_rounded,
                    color: AppColors.text,
                  ),
                  onPressed: service.previous,
                ),
                Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    iconSize: 40,
                    padding: const EdgeInsets.all(12),
                    icon: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: AppColors.text,
                    ),
                    onPressed: service.togglePlay,
                  ),
                ),
                IconButton(
                  iconSize: 38,
                  icon: const Icon(
                    Icons.skip_next_rounded,
                    color: AppColors.text,
                  ),
                  onPressed: service.next,
                ),
                IconButton(
                  icon: Icon(
                    loop == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: loop == LoopMode.off
                        ? AppColors.textMuted
                        : AppColors.accent,
                  ),
                  onPressed: service.cycleRepeat,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const _VolumeRow(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showQueue(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final queue = ref.watch(queueProvider);
          final index = ref.watch(currentIndexProvider).value;
          final service = ref.read(playerServiceProvider);
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ListView.builder(
              itemCount: queue.length,
              itemBuilder: (context, i) {
                final t = queue[i];
                return ListTile(
                  selected: i == index,
                  selectedColor: AppColors.accent,
                  title: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    t.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => service.seekToIndex(i),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SeekBar extends ConsumerStatefulWidget {
  const _SeekBar();

  @override
  ConsumerState<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends ConsumerState<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final service = ref.read(playerServiceProvider);

    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final value = (_drag ?? position.inMilliseconds.toDouble())
        .clamp(0.0, maxMs)
        .toDouble();

    return Column(
      children: [
        Slider(
          value: value,
          max: maxMs,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.elevated,
          onChanged: (v) => setState(() => _drag = v),
          onChangeEnd: (v) {
            service.seek(Duration(milliseconds: v.round()));
            setState(() => _drag = null);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(value.round()),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              Text(
                formatDuration(duration.inMilliseconds),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VolumeRow extends ConsumerWidget {
  const _VolumeRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(audioPlayerProvider);
    final service = ref.read(playerServiceProvider);

    return StreamBuilder<double>(
      stream: player.volumeStream,
      initialData: player.volume,
      builder: (context, snapshot) {
        final volume = snapshot.data ?? 1.0;
        return Row(
          children: [
            const Icon(Icons.volume_down_rounded, color: AppColors.textMuted),
            Expanded(
              child: Slider(
                value: volume.clamp(0.0, 1.0),
                activeColor: AppColors.accent,
                inactiveColor: AppColors.elevated,
                onChanged: (v) => service.setVolume(v),
              ),
            ),
            const Icon(Icons.volume_up_rounded, color: AppColors.textMuted),
          ],
        );
      },
    );
  }
}
