import 'package:on_audio_query/on_audio_query.dart';

import '../../../shared/models/track.dart';
import '../../metadata/domain/filename_parser.dart';

class ScannerService {
  final OnAudioQuery _query = OnAudioQuery();

  Future<bool> hasPermission() => _query.permissionsStatus();

  Future<bool> requestPermission() => _query.permissionsRequest();

  /// Lit les morceaux via MediaStore. Ne modifie jamais les fichiers audio.
  Future<List<Track>> scan() async {
    final songs = await _query.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    final tracks = <Track>[];
    for (final s in songs) {
      if (s.isMusic == false) continue; // ignore sonneries et notifications

      final fileName = s.displayName;
      var title = _clean(s.title);
      var artist = _clean(s.artist);
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
          id: s.id,
          filePath: s.data,
          fileName: fileName,
          title: title,
          artist: finalArtist,
          mainArtist: artist == null
              ? Track.unknown
              : FilenameParser.mainArtist(finalArtist),
          album: _clean(s.album) ?? Track.unknown,
          genre: _clean(s.genre) ?? Track.unknown,
          durationMs: s.duration ?? 0,
          fileSize: s.size,
          dateAdded: s.dateAdded ?? 0,
          dateModified: s.dateModified ?? 0,
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
