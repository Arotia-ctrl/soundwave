import 'package:flutter/services.dart';

import '../../../shared/models/track.dart';
import '../../metadata/domain/filename_parser.dart';

class ScannerService {
  static const MethodChannel _channel = MethodChannel('soundwave/library');

  /// Vrai quand Android a bloqué la demande : seul l'écran des paramètres
  /// permet alors d'autoriser l'accès.
  bool _blocked = false;

  Future<bool> hasPermission() async =>
      (await _channel.invokeMethod<bool>('hasPermission')) ?? false;

  Future<bool> requestPermission() async {
    if (_blocked && !await hasPermission()) {
      await _channel.invokeMethod<void>('openSettings');
      return false;
    }
    final status = await _channel.invokeMethod<String>('requestPermission');
    _blocked = status == 'blocked';
    return status == 'granted';
  }

  /// Lit les morceaux via MediaStore. Ne modifie jamais les fichiers audio.
  Future<List<Track>> scan() async {
    final raw =
        await _channel.invokeMethod<List<dynamic>>('queryTracks') ?? const [];

    final tracks = <Track>[];
    for (final item in raw) {
      final m = Map<String, dynamic>.from(item as Map);

      final fileName = (m['displayName'] as String?) ?? '';
      var title = _clean(m['title'] as String?);
      var artist = _clean(m['artist'] as String?);
      var source = 'metadata';

      // Artiste absent des métadonnées : on essaie "Artiste - Titre" dans le nom
      if (artist == null) {
        final parsed = FilenameParser.parse(fileName);
        if (parsed.artist != null) {
          artist = parsed.artist;
          title = parsed.title;
          source = 'filename';
        }
      }
      if (title == null) {
        title = FilenameParser.parse(fileName).title;
        source = 'filename';
      }

      final finalArtist = artist ?? Track.unknown;

      tracks.add(
        Track(
          id: (m['id'] as num).toInt(),
          filePath: (m['data'] as String?) ?? '',
          fileName: fileName,
          title: title,
          artist: finalArtist,
          mainArtist: artist == null
              ? Track.unknown
              : FilenameParser.mainArtist(finalArtist),
          album: _clean(m['album'] as String?) ?? Track.unknown,
          genre: _clean(m['genre'] as String?) ?? Track.unknown,
          durationMs: (m['duration'] as num?)?.toInt() ?? 0,
          fileSize: (m['size'] as num?)?.toInt() ?? 0,
          dateAdded: (m['dateAdded'] as num?)?.toInt() ?? 0,
          dateModified: (m['dateModified'] as num?)?.toInt() ?? 0,
          metadataSource: source,
        ),
      );
    }
    return tracks;
  }

  static String? _clean(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty || v.toLowerCase() == '<unknown>') return null;
    return v;
  }
}
