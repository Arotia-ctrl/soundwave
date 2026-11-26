import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/track.dart';
import '../../library/data/user_data_providers.dart';
import '../../library/presentation/library_controller.dart';
import '../domain/playlist.dart';
import 'playlist_repository.dart';

final playlistRepositoryProvider = Provider<PlaylistRepository>(
  (ref) => PlaylistRepository(),
);

class PlaylistsNotifier extends Notifier<List<Playlist>> {
  PlaylistRepository get _repo => ref.read(playlistRepositoryProvider);

  @override
  List<Playlist> build() {
    Future.microtask(reload);
    return const [];
  }

  Future<void> reload() async {
    try {
      state = await _repo.loadAll();
    } catch (e) {
      debugPrint('Playlists : $e');
    }
  }

  Future<int?> create(String name) async {
    try {
      final id = await _repo.create(name);
      await reload();
      return id;
    } catch (e) {
      debugPrint('Playlists : $e');
      return null;
    }
  }

  Future<void> rename(int id, String name) async {
    try {
      await _repo.rename(id, name);
      await reload();
    } catch (e) {
      debugPrint('Playlists : $e');
    }
  }

  Future<void> delete(int id) async {
    try {
      await _repo.delete(id);
      await reload();
    } catch (e) {
      debugPrint('Playlists : $e');
    }
  }

  Future<void> addTrack(int playlistId, int trackId) async {
    try {
      await _repo.addTrack(playlistId, trackId);
      await reload();
    } catch (e) {
      debugPrint('Playlists : $e');
    }
  }

  Future<void> removeTrack(int playlistId, int trackId) async {
    try {
      await _repo.removeTrack(playlistId, trackId);
      await reload();
    } catch (e) {
      debugPrint('Playlists : $e');
    }
  }

  /// [visibleOrder] : nouvel ordre des morceaux affichés. Les morceaux de la
  /// playlist qui n'existent plus dans la bibliothèque sont gardés à la fin.
  Future<void> setOrder(int playlistId, List<int> visibleOrder) async {
    final playlist = state.where((p) => p.id == playlistId).firstOrNull;
    if (playlist == null) return;
    final missing = playlist.trackIds
        .where((id) => !visibleOrder.contains(id))
        .toList();
    final all = [...visibleOrder, ...missing];

    state = [
      for (final p in state)
        if (p.id == playlistId)
          Playlist(id: p.id, name: p.name, trackIds: all)
        else
          p,
    ];

    try {
      await _repo.saveOrder(playlistId, all);
    } catch (e) {
      debugPrint('Playlists : $e');
      await reload();
    }
  }
}

final playlistsProvider = NotifierProvider<PlaylistsNotifier, List<Playlist>>(
  PlaylistsNotifier.new,
);

// ---------------- Playlists automatiques ----------------

class AutoPlaylist {
  final String key;
  final String name;
  final IconData icon;
  final List<Track> tracks;

  const AutoPlaylist({
    required this.key,
    required this.name,
    required this.icon,
    required this.tracks,
  });
}

/// Se recalcule toute seule quand la bibliothèque, les favoris ou
/// l'historique changent.
final autoPlaylistsProvider = Provider<List<AutoPlaylist>>((ref) {
  final all = ref.watch(libraryProvider.select((s) => s.tracks));
  final favorites = ref.watch(favoritesProvider);
  final history = ref.watch(historyProvider);

  final byId = {for (final t in all) t.id: t};
  List<Track> fromIds(Iterable<int> ids) => [
    for (final id in ids)
      if (byId[id] != null) byId[id]!,
  ];

  final recentlyAdded = [...all]
    ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

  final mostPlayed = history.counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return [
    AutoPlaylist(
      key: 'favorites',
      name: 'Favorites',
      icon: Icons.favorite_rounded,
      tracks: fromIds(favorites),
    ),
    AutoPlaylist(
      key: 'recent',
      name: 'Recently Played',
      icon: Icons.history_rounded,
      tracks: fromIds(history.recent),
    ),
    AutoPlaylist(
      key: 'most',
      name: 'Most Played',
      icon: Icons.trending_up_rounded,
      tracks: fromIds(mostPlayed.take(50).map((e) => e.key)),
    ),
    AutoPlaylist(
      key: 'added',
      name: 'Recently Added',
      icon: Icons.fiber_new_rounded,
      tracks: recentlyAdded.take(50).toList(),
    ),
  ];
});
