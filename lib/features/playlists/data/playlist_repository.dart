import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/playlist.dart';

class PlaylistRepository {
  Future<List<Playlist>> loadAll() async {
    final db = await AppDatabase.instance;
    final playlists = await db.query('playlists', orderBy: 'created_at ASC');
    final rows = await db.query(
      'playlist_tracks',
      orderBy: 'playlist_id ASC, position ASC',
    );

    final byPlaylist = <int, List<int>>{};
    for (final r in rows) {
      byPlaylist
          .putIfAbsent(r['playlist_id'] as int, () => [])
          .add(r['track_id'] as int);
    }

    return [
      for (final p in playlists)
        Playlist(
          id: p['id'] as int,
          name: p['name'] as String,
          trackIds: byPlaylist[p['id'] as int] ?? <int>[],
        ),
    ];
  }

  Future<int> create(String name) async {
    final db = await AppDatabase.instance;
    return db.insert('playlists', {
      'name': name,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> rename(int id, String name) async {
    final db = await AppDatabase.instance;
    await db.update(
      'playlists',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete(
        'playlist_tracks',
        where: 'playlist_id = ?',
        whereArgs: [id],
      );
      await txn.delete('playlists', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<void> addTrack(int playlistId, int trackId) async {
    final db = await AppDatabase.instance;
    final res = await db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS next '
      'FROM playlist_tracks WHERE playlist_id = ?',
      [playlistId],
    );
    final next = (res.first['next'] as int?) ?? 0;
    await db.insert('playlist_tracks', {
      'playlist_id': playlistId,
      'track_id': trackId,
      'position': next,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeTrack(int playlistId, int trackId) async {
    final db = await AppDatabase.instance;
    await db.delete(
      'playlist_tracks',
      where: 'playlist_id = ? AND track_id = ?',
      whereArgs: [playlistId, trackId],
    );
  }

  Future<void> saveOrder(int playlistId, List<int> trackIds) async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      for (var i = 0; i < trackIds.length; i++) {
        await txn.update(
          'playlist_tracks',
          {'position': i},
          where: 'playlist_id = ? AND track_id = ?',
          whereArgs: [playlistId, trackIds[i]],
        );
      }
    });
  }
}
