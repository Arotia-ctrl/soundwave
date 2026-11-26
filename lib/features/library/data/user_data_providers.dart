import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/track.dart';
import '../../player/data/player_providers.dart';
import 'user_data_repository.dart';

final userDataRepositoryProvider = Provider<UserDataRepository>(
  (ref) => UserDataRepository(),
);

// ---------------- Favoris ----------------

class FavoritesNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() {
    Future.microtask(_load);
    return <int>{};
  }

  Future<void> _load() async {
    try {
      final ids = await ref.read(userDataRepositoryProvider).loadFavorites();
      state = ids.toSet();
    } catch (e) {
      debugPrint('Favoris : $e');
    }
  }

  Future<void> toggle(int trackId) async {
    final repo = ref.read(userDataRepositoryProvider);
    try {
      if (state.contains(trackId)) {
        state = {...state}..remove(trackId);
        await repo.removeFavorite(trackId);
      } else {
        state = {trackId, ...state};
        await repo.addFavorite(trackId);
      }
    } catch (e) {
      debugPrint('Favoris : $e');
    }
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<int>>(
  FavoritesNotifier.new,
);

// ---------------- Historique ----------------

class HistoryState {
  final List<int> recent;
  final Map<int, int> counts;

  const HistoryState({this.recent = const [], this.counts = const {}});
}

class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    Future.microtask(load);
    return const HistoryState();
  }

  Future<void> load() async {
    try {
      final repo = ref.read(userDataRepositoryProvider);
      final recent = await repo.recentIds();
      final counts = await repo.playCounts();
      state = HistoryState(recent: recent, counts: counts);
    } catch (e) {
      debugPrint('Historique : $e');
    }
  }

  Future<void> record(int trackId) async {
    try {
      await ref.read(userDataRepositoryProvider).recordPlay(trackId);
      await load();
    } catch (e) {
      debugPrint('Historique : $e');
    }
  }

  Future<void> clear() async {
    try {
      await ref.read(userDataRepositoryProvider).clearHistory();
      await load();
    } catch (e) {
      debugPrint('Historique : $e');
    }
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(
  HistoryNotifier.new,
);

/// Compte une écoute quand un morceau a joué 15 secondes sans être changé.
/// À surveiller une fois, tout en haut de l'application.
final historyRecorderProvider = Provider<void>((ref) {
  Timer? timer;

  ref.listen<Track?>(currentTrackProvider, (previous, next) {
    timer?.cancel();
    if (next == null) return;
    final id = next.id;
    timer = Timer(const Duration(seconds: 15), () {
      ref.read(historyProvider.notifier).record(id);
    });
  });

  ref.onDispose(() => timer?.cancel());
});
