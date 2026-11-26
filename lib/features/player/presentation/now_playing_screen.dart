import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../shared/widgets/track_artwork.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format.dart';
import '../data/player_providers.dart';
import '../../library/data/user_data_providers.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Expanded(
                child: Center(child: _Artwork(trackId: track.id)),
              ),
              const SizedBox(height: 32),
              Text(
                track.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                track.artist,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              const _SeekBar(),
              const SizedBox(height: 28),
              const _MainControls(),
              const SizedBox(height: 32),
              const _SecondaryControls(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  final int trackId;
  const _Artwork({required this.trackId});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 40,
                spreadRadius: 2,
              ),
            ],
          ),
          child: TrackArtwork(
            trackId: trackId,
            size: side,
            radius: 28,
            pixelSize: 800,
          ),
        );
      },
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
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
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

class _MainControls extends ConsumerWidget {
  const _MainControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playing = ref.watch(playingProvider).value ?? false;
    final service = ref.read(playerServiceProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SquircleButton(
          icon: Icons.skip_previous_rounded,
          onTap: service.previous,
        ),
        const SizedBox(width: 24),
        Material(
          color: AppColors.primary,
          elevation: 10,
          shadowColor: AppColors.primary,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: service.togglePlay,
            child: SizedBox(
              width: 84,
              height: 84,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(playing),
                    size: 46,
                    color: AppColors.text,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        _SquircleButton(icon: Icons.skip_next_rounded, onTap: service.next),
      ],
    );
  }
}

class _SquircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Material(
      color: AppColors.elevated,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 66,
          height: 66,
          child: Icon(icon, size: 36, color: AppColors.text),
        ),
      ),
    );
  }
}

class _SecondaryControls extends ConsumerWidget {
  const _SecondaryControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(currentTrackProvider);
    final shuffle = ref.watch(shuffleProvider).value ?? false;
    final loop = ref.watch(loopModeProvider).value ?? LoopMode.off;
    final service = ref.read(playerServiceProvider);
    final isFavorite =
        track != null &&
        ref.watch(favoritesProvider.select((s) => s.contains(track.id)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ToggleButton(
          icon: Icons.shuffle_rounded,
          active: shuffle,
          onTap: () => service.setShuffle(!shuffle),
        ),
        _ToggleButton(
          icon: loop == LoopMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          active: loop != LoopMode.off,
          onTap: service.cycleRepeat,
        ),
        _ToggleButton(
          icon: isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          active: isFavorite,
          onTap: () {
            if (track != null) {
              ref.read(favoritesProvider.notifier).toggle(track.id);
            }
          },
        ),
        _ToggleButton(
          icon: Icons.queue_music_rounded,
          active: false,
          onTap: () => _showQueue(context),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: active
          ? AppColors.primary.withValues(alpha: 0.25)
          : Colors.transparent,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 56,
          height: 56,
          child: Icon(
            icon,
            size: 26,
            color: active ? AppColors.accent : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
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
