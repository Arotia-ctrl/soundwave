import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/track_artwork.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format.dart';
import '../../../../shared/models/track.dart';
import '../../../analyzer/presentation/analysis_controller.dart';
import '../../../analyzer/presentation/analysis_sheet.dart';
import '../../../classification/domain/classifier.dart';
import '../../../player/data/player_providers.dart';
import '../../../playlists/presentation/widgets/playlist_dialogs.dart';
import '../../data/user_data_providers.dart';

class TrackTile extends ConsumerWidget {
  final Track track;
  final List<Track> queue;
  final int index;

  /// Renseigné uniquement dans une playlist : ajoute « Retirer de cette playlist ».
  final VoidCallback? onRemove;

  const TrackTile({
    super.key,
    required this.track,
    required this.queue,
    required this.index,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrent = ref.watch(
      currentTrackProvider.select((t) => t?.id == track.id),
    );
    final isFavorite = ref.watch(
      favoritesProvider.select((s) => s.contains(track.id)),
    );
    final result = ref.watch(
      analysisProvider.select((s) => s.results[track.id]),
    );

    var subtitle = '${track.artist} · ${formatDuration(track.durationMs)}';
    if (result != null && result.mood != Mood.unknown) {
      subtitle += ' · ${result.mood.label}';
    }
    if (result != null && result.analyzed && result.bpm! > 0) {
      subtitle += ' · ${result.bpm!.round()} BPM';
    }

    return ListTile(
      onTap: () => ref.read(playerServiceProvider).playQueue(queue, index),
      leading: TrackArtwork(trackId: track.id, size: 48, radius: 8),
      title: Text(
        track.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: isCurrent ? AppColors.accent : AppColors.text),
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
        color: AppColors.elevated,
        onSelected: (value) {
          switch (value) {
            case 'favorite':
              ref.read(favoritesProvider.notifier).toggle(track.id);
            case 'playlist':
              showAddToPlaylistSheet(context, track);
            case 'analysis':
              showAnalysisSheet(context, track);
            case 'remove':
              onRemove?.call();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'favorite',
            child: Text(
              isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
            ),
          ),
          const PopupMenuItem(
            value: 'playlist',
            child: Text('Ajouter à une playlist'),
          ),
          const PopupMenuItem(
            value: 'analysis',
            child: Text('Analyse et catégorie'),
          ),
          if (onRemove != null)
            const PopupMenuItem(
              value: 'remove',
              child: Text('Retirer de cette playlist'),
            ),
        ],
      ),
    );
  }
}
