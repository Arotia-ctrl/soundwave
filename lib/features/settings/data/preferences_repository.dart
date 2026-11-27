import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';

class PreferencesRepository {
  static const _table = 'user_preferences';

  Future<Map<String, String>> loadAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(_table);
    return {for (final r in rows) r['key'] as String: r['value'] as String};
  }

  Future<void> set(String key, String value) async {
    final db = await AppDatabase.instance;
    await db.insert(_table, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setAll(Map<String, String> values) async {
    final db = await AppDatabase.instance;
    final batch = db.batch();
    values.forEach((key, value) {
      batch.insert(_table, {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    await batch.commit(noResult: true);
  }
}
