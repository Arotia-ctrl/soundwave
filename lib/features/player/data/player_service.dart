import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../../../shared/models/track.dart';

class PlayerService {
  final AudioPlayer player;
  final void Function(List<Track>) onQueueChanged;

  PlayerService(this.player, this.onQueueChanged);

  /// Remplace la file par [tracks] et démarre au morceau [index].
  Future<void> playQueue(List<Track> tracks, int index) async {
    if (tracks.isEmpty) return;
    onQueueChanged(tracks);
    try {
      await player.setAudioSources(
        tracks.map(_toSource).toList(),
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      unawaited(player.play());
    } catch (e) {
      debugPrint('Erreur de lecture : $e');
    }
  }

  AudioSource _toSource(Track t) {
    return AudioSource.uri(
      Uri.parse('content://media/external/audio/media/${t.id}'),
      tag: MediaItem(
        id: t.id.toString(),
        title: t.title,
        artist: t.artist,
        album: t.album,
        duration: Duration(milliseconds: t.durationMs),
      ),
    );
  }

  void togglePlay() {
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  Future<void> next() => player.seekToNext();

  Future<void> previous() async {
    // Après 3 secondes, "précédent" revient au début du morceau
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) => player.seek(position);

  Future<void> seekToIndex(int index) async {
    await player.seek(Duration.zero, index: index);
    unawaited(player.play());
  }

  Future<void> setShuffle(bool enabled) async {
    await player.setShuffleModeEnabled(enabled);
    if (enabled) await player.shuffle();
  }

  Future<void> cycleRepeat() {
    final next = switch (player.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    return player.setLoopMode(next);
  }

  Future<void> setVolume(double volume) => player.setVolume(volume);
}
