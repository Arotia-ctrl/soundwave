import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

class DataMaintenanceRepository {
  static const _trackTables = [
    'favorites',
    'listening_history',
    'playlist_tracks',
    'analysis_results',
  ];

  /// Identifiants stockés qui ne correspondent plus à aucun fichier existant.
  static Set<int> findOrphans(Set<int> stored, Set<int> existing) =>
      stored.difference(existing);

  Future<Map<String, Set<int>>> _orphansByTable(
    Database db,
    Set<int> existing,
  ) async {
    final result = <String, Set<int>>{};
    for (final table in _trackTables) {
      final rows = await db.rawQuery('SELECT DISTINCT track_id FROM $table');
      final stored = {for (final r in rows) r['track_id'] as int};
      final orphans = findOrphans(stored, existing);
      if (orphans.isNotEmpty) result[table] = orphans;
    }
    return result;
  }

  Future<int> countOrphans(Set<int> existingTrackIds) async {
    final db = await AppDatabase.instance;
    final byTable = await _orphansByTable(db, existingTrackIds);
    return byTable.values.fold<int>(0, (sum, ids) => sum + ids.length);
  }

  Future<int> purgeOrphans(Set<int> existingTrackIds) async {
    final db = await AppDatabase.instance;
    final byTable = await _orphansByTable(db, existingTrackIds);
    var count = 0;
    await db.transaction((txn) async {
      final batch = txn.batch();
      byTable.forEach((table, ids) {
        for (final id in ids) {
          batch.delete(table, where: 'track_id = ?', whereArgs: [id]);
          count++;
        }
      });
      await batch.commit(noResult: true);
    });
    return count;
  }

  /// Efface favoris, playlists, historique, analyses et position de lecture.
  /// Les réglages sont conservés. Les fichiers audio ne sont jamais touchés.
  Future<void> resetAll() async {
    final db = await AppDatabase.instance;
    await db.transaction((txn) async {
      await txn.delete('playlist_tracks');
      await txn.delete('playlists');
      await txn.delete('favorites');
      await txn.delete('listening_history');
      await txn.delete('analysis_results');
      await txn.delete('user_preferences', where: "key LIKE 'playback.%'");
    });
  }
}

final dataMaintenanceProvider = Provider<DataMaintenanceRepository>(
  (ref) => DataMaintenanceRepository(),
);
