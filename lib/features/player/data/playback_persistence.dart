import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../library/presentation/library_controller.dart';
import '../../settings/data/settings_controller.dart';
import 'player_providers.dart';

/// À surveiller une fois, en haut de l'application.
final playbackPersistenceProvider = Provider<void>((ref) {
  final prefs = ref.read(preferencesRepositoryProvider);
  Timer? timer;
  var restored = false;

  Future<void> safe(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      debugPrint('Reprise de lecture : $e');
    }
  }

  Future<void> savePosition() async {
    if (ref.read(queueProvider).isEmpty) return;
    final player = ref.read(audioPlayerProvider);
    await prefs.setAll({
      'playback.index': '${player.currentIndex ?? 0}',
      'playback.position_ms': '${player.position.inMilliseconds}',
    });
  }

  Future<void> restore() async {
    final map = await prefs.loadAll();
    if (!AppSettings.fromMap(map).resumePlayback) return;
    if (ref.read(queueProvider).isNotEmpty) return; // déjà lancé par l'utilisateur

    final ids = (map['playback.queue'] ?? '')
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    if (ids.isEmpty) return;

    final byId = {for (final t in ref.read(libraryProvider).tracks) t.id: t};
    final tracks = [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
    if (tracks.isEmpty) return;

    // L'index sauvegardé se rapporte à la liste d'origine : on retrouve le
    // morceau par son identifiant, au cas où certains fichiers aient disparu.
    final savedIndex = int.tryParse(map['playback.index'] ?? '') ?? 0;
    final savedId = (savedIndex >= 0 && savedIndex < ids.length)
        ? ids[savedIndex]
        : ids.first;
    var index = tracks.indexWhere((t) => t.id == savedId);
    var positionMs = int.tryParse(map['playback.position_ms'] ?? '') ?? 0;
    if (index < 0) {
      index = 0;
      positionMs = 0;
    }

    await ref
        .read(playerServiceProvider)
        .prepareQueue(tracks, index, Duration(milliseconds: positionMs));
  }

  // File d'attente modifiée : on la mémorise
  ref.listen(queueProvider, (previous, next) {
    if (next.isEmpty) return;
    safe(() => prefs.set('playback.queue', next.map((t) => t.id).join(',')));
    timer ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (ref.read(audioPlayerProvider).playing) safe(savePosition);
    });
  });

  // Morceau changé : on mémorise l'index et la position
  ref.listen(currentTrackProvider, (previous, next) {
    if (next != null) safe(savePosition);
  });

  // App mise en arrière-plan : dernière sauvegarde de la position
  final lifecycle = AppLifecycleListener(onPause: () => safe(savePosition));

  // Restauration, une fois la bibliothèque chargée
  ref.listen(libraryProvider, (previous, next) {
    if (restored) return;
    if (next.status == LibraryStatus.ready && next.tracks.isNotEmpty) {
      restored = true;
      safe(restore);
    }
  });

  ref.onDispose(() {
    timer?.cancel();
    lifecycle.dispose();
  });
});