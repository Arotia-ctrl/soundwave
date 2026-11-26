import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/track.dart';

import '../../library/presentation/library_controller.dart';
import '../../library/presentation/widgets/track_tile.dart';
import '../../player/data/player_providers.dart';
import '../data/playlist_providers.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  /// Une playlist de l'utilisateur...
  final int? playlistId;

  /// ...ou une playlist automatique ('favorites', 'recent', 'most', 'added').
  final String? autoKey;

  const PlaylistDetailScreen({super.key, this.playlistId, this.autoKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final library = ref.watch(libraryProvider.select((s) => s.tracks));
    final byId = {for (final t in library) t.id: t};
    final editable = playlistId != null;

    final String title;
    final List<Track> tracks;

    if (playlistId != null) {
      final playlist = ref
          .watch(playlistsProvider)
          .where((p) => p.id == playlistId)
          .firstOrNull;
      if (playlist == null) return _notFound();
      title = playlist.name;
      tracks = [
        for (final id in playlist.trackIds)
          if (byId[id] != null) byId[id]!,
      ];
    } else {
      final auto = ref
          .watch(autoPlaylistsProvider)
          .where((a) => a.key == autoKey)
          .firstOrNull;
      if (auto == null) return _notFound();
      title = auto.name;
      tracks = auto.tracks;
    }

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: tracks.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Cette playlist est vide.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                _Actions(tracks: tracks),
                Expanded(
                  child: editable
                      ? _editableList(ref, tracks)
                      : _plainList(tracks),
                ),
              ],
            ),
    );
  }

  Widget _notFound() => Scaffold(
    appBar: AppBar(),
    body: const Center(child: Text('Playlist introuvable')),
  );

  Widget _plainList(List<Track> tracks) {
    return ListView.builder(
      itemCount: tracks.length,
      itemBuilder: (context, i) =>
          TrackTile(track: tracks[i], queue: tracks, index: i),
    );
  }

  Widget _editableList(WidgetRef ref, List<Track> tracks) {
    final notifier = ref.read(playlistsProvider.notifier);
    return ReorderableListView.builder(
      itemCount: tracks.length,
      onReorderItem: (oldIndex, newIndex) {
        final ids = tracks.map((t) => t.id).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        notifier.setOrder(playlistId!, ids);
      },
      itemBuilder: (context, i) => TrackTile(
        key: ValueKey(tracks[i].id),
        track: tracks[i],
        queue: tracks,
        index: i,
        onRemove: () => notifier.removeTrack(playlistId!, tracks[i].id),
      ),
    );
  }
}

class _Actions extends ConsumerWidget {
  final List<Track> tracks;
  const _Actions({required this.tracks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(playerServiceProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => service.playQueue(tracks, 0),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Lecture'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                await service.playQueue(
                  tracks,
                  Random().nextInt(tracks.length),
                );
                await service.setShuffle(true);
              },
              icon: const Icon(Icons.shuffle_rounded),
              label: const Text('Aléatoire'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
