import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

class ArtworkEntry {
  final Uint8List? bytes; // null = ce morceau n'a pas de pochette
  const ArtworkEntry(this.bytes);
}

class ArtworkCache {
  static const MethodChannel _channel = MethodChannel('soundwave/library');
  static const int _maxEntries = 300;

  static final LinkedHashMap<String, ArtworkEntry> _cache = LinkedHashMap();
  static final Map<String, Future<Uint8List?>> _inFlight = {};

  static String key(int id, int px) => '$id@$px';

  /// Lecture immédiate si déjà en cache.
  static ArtworkEntry? peek(String key) {
    final entry = _cache.remove(key);
    if (entry != null) _cache[key] = entry; // le plus récent en dernier
    return entry;
  }

  static Future<Uint8List?> load(int id, int px) {
    final k = key(id, px);
    final cached = peek(k);
    if (cached != null) return Future.value(cached.bytes);
    return _inFlight[k] ??= _fetch(id, px, k);
  }

  static Future<Uint8List?> _fetch(int id, int px, String k) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('artwork', {
        'id': id,
        'size': px,
      });
      _cache[k] = ArtworkEntry(bytes);
      if (_cache.length > _maxEntries) _cache.remove(_cache.keys.first);
      return bytes;
    } catch (_) {
      return null; // erreur temporaire : on ne la mémorise pas
    } finally {
      _inFlight.remove(k);
    }
  }
}

class TrackArtwork extends StatefulWidget {
  final int trackId;
  final double size;
  final double radius;
  final int pixelSize;

  const TrackArtwork({
    super.key,
    required this.trackId,
    required this.size,
    this.radius = 8,
    this.pixelSize = 192,
  });

  @override
  State<TrackArtwork> createState() => _TrackArtworkState();
}

class _TrackArtworkState extends State<TrackArtwork> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(TrackArtwork old) {
    super.didUpdateWidget(old);
    if (old.trackId != widget.trackId || old.pixelSize != widget.pixelSize) {
      _resolve();
    }
  }

  void _resolve() {
    final id = widget.trackId;
    final px = widget.pixelSize;

    final cached = ArtworkCache.peek(ArtworkCache.key(id, px));
    if (cached != null) {
      _bytes = cached.bytes;
      return;
    }

    // On garde l'ancienne image à l'écran le temps du chargement
    ArtworkCache.load(id, px).then((bytes) {
      if (!mounted || widget.trackId != id || widget.pixelSize != px) return;
      setState(() => _bytes = bytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final radius = BorderRadius.circular(widget.radius);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: ClipRRect(
        borderRadius: radius,
        child: bytes == null
            ? Container(
                color: AppColors.elevated,
                child: Icon(
                  Icons.music_note_rounded,
                  size: widget.size * 0.45,
                  color: AppColors.accent,
                ),
              )
            : Image.memory(
                bytes,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                cacheWidth: widget.pixelSize,
              ),
      ),
    );
  }
}
