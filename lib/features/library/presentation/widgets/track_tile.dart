import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../shared/models/track.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;

  const TrackTile({super.key, required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
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
        style: const TextStyle(color: AppColors.text),
      ),
      subtitle: Text(
        '${track.artist} · ${formatDuration(track.durationMs)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
