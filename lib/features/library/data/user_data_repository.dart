import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

class UserDataRepository {
  // ---- Favoris ----

  /// Identifiants des favoris, du plus récent au plus ancien.
  Future<List<int>> loadFavorites() async {
    final db = await AppDatabase.instance;
    final rows = await db.query('favorites', orderBy: 'added_at DESC');
    return [for (final r in rows) r['track_id'] as int];
  }

  Future<void> addFavorite(int trackId) async {
    final db = await AppDatabase.instance;
    await db.insert('favorites', {
      'track_id': trackId,
      'added_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> removeFavorite(int trackId) async {
    final db = await AppDatabase.instance;
    await db.delete('favorites', where: 'track_id = ?', whereArgs: [trackId]);
  }

  // ---- Historique ----

  Future<void> recordPlay(int trackId) async {
    final db = await AppDatabase.instance;
    await db.insert('listening_history', {
      'track_id': trackId,
      'played_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Morceaux distincts, du plus récemment écouté au plus ancien.
  Future<List<int>> recentIds({int limit = 50}) async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery(
      'SELECT track_id, MAX(played_at) AS last_played '
      'FROM listening_history GROUP BY track_id '
      'ORDER BY last_played DESC LIMIT ?',
      [limit],
    );
    return [for (final r in rows) r['track_id'] as int];
  }

  Future<Map<int, int>> playCounts() async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery(
      'SELECT track_id, COUNT(*) AS plays '
      'FROM listening_history GROUP BY track_id',
    );
    return {for (final r in rows) r['track_id'] as int: r['plays'] as int};
  }

  Future<void> clearHistory() async {
    final db = await AppDatabase.instance;
    await db.delete('listening_history');
  }
}
