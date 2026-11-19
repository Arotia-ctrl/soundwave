import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../shared/models/track.dart';
import '../../../player/data/player_providers.dart';

class TrackTile extends ConsumerWidget {
  final Track track;
  final List<Track> queue;
  final int index;

  const TrackTile({
    super.key,
    required this.track,
    required this.queue,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(currentTrackProvider)?.id == track.id;

    return ListTile(
      onTap: () => ref.read(playerServiceProvider).playQueue(queue, index),
      leading: QueryArtworkWidget(
        id: track.id,
        type: ArtworkType.AUDIO,
        artworkWidth: 48,
        artworkHeight: 48,
        artworkBorder: BorderRadius.circular(8),
        nullArtworkWidget: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.elevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.music_note_rounded, color: AppColors.accent),
        ),
      ),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isCurrent ? AppColors.accent : AppColors.text),
      ),
      subtitle: Text(
        '${track.artist} · ${formatDuration(track.durationMs)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
