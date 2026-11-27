import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../../classification/domain/classifier.dart';
import '../domain/analysis_result.dart';
import '../domain/raw_features.dart';

class AnalysisRepository {
  static const _table = 'analysis_results';

  Future<Map<int, AnalysisResult>> loadAll() async {
    final db = await AppDatabase.instance;
    final rows = await db.query(_table);
    return {
      for (final r in rows) r['track_id'] as int: AnalysisResult.fromRow(r),
    };
  }

  Future<AnalysisResult?> load(int trackId) async {
    final db = await AppDatabase.instance;
    final rows = await db.query(
      _table,
      where: 'track_id = ?',
      whereArgs: [trackId],
      limit: 1,
    );
    return rows.isEmpty ? null : AnalysisResult.fromRow(rows.first);
  }

  Map<String, Object?> _featureColumns(RawFeatures f, Classification c) => {
    'bpm': f.bpm,
    'energy': c.energy,
    'loudness': f.loudnessDb,
    'dynamic_range': f.dynamicRangeDb,
    'spectral_centroid': f.centroidHz,
    'rhythm_strength': f.rhythmStrength,
    'tempo_category': c.tempo.db,
    'analysis_status': 'ok',
    'analyzed_at': DateTime.now().millisecondsSinceEpoch,
  };

  /// Une catégorie corrigée à la main n'est jamais écrasée.
  Future<void> saveAnalysis(
    int trackId,
    RawFeatures f,
    Classification c,
  ) async {
    final db = await AppDatabase.instance;
    final existing = await load(trackId);
    final columns = _featureColumns(f, c);

    if (existing != null && existing.manuallyOverridden) {
      await db.update(
        _table,
        columns,
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
    } else {
      await db.insert(_table, {
        'track_id': trackId,
        ...columns,
        'mood': c.mood.db,
        'confidence': c.confidence,
        'manually_overridden': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// N'écrase jamais un résultat existant.
  Future<void> saveFailure(int trackId) async {
    final db = await AppDatabase.instance;
    await db.insert(_table, {
      'track_id': trackId,
      'mood': Mood.unknown.db,
      'tempo_category': TempoCategory.unknown.db,
      'analysis_status': 'failed',
      'manually_overridden': 0,
      'analyzed_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> setManualMood(int trackId, Mood mood) async {
    final db = await AppDatabase.instance;
    final existing = await load(trackId);
    if (existing == null) {
      await db.insert(_table, {
        'track_id': trackId,
        'mood': mood.db,
        'tempo_category': TempoCategory.unknown.db,
        'analysis_status': 'manual',
        'manually_overridden': 1,
        'analyzed_at': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      await db.update(
        _table,
        {'mood': mood.db, 'manually_overridden': 1},
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
    }
  }

  /// [recomputed] : catégorie recalculée depuis les mesures stockées, ou null
  /// s'il n'y a pas de mesures (la ligne est alors supprimée).
  Future<void> clearManualMood(int trackId, Classification? recomputed) async {
    final db = await AppDatabase.instance;
    if (recomputed == null) {
      await db.delete(_table, where: 'track_id = ?', whereArgs: [trackId]);
    } else {
      await db.update(
        _table,
        {
          'mood': recomputed.mood.db,
          'confidence': recomputed.confidence,
          'manually_overridden': 0,
        },
        where: 'track_id = ?',
        whereArgs: [trackId],
      );
    }
  }

  Future<void> deleteFailed() async {
    final db = await AppDatabase.instance;
    await db.delete(_table, where: "analysis_status = 'failed'");
  }

  Future<void> updateClassification(int trackId, Classification c) async {
    final db = await AppDatabase.instance;
    await db.update(
      _table,
      {
        'mood': c.mood.db,
        'tempo_category': c.tempo.db,
        'energy': c.energy,
        'confidence': c.confidence,
      },
      where: 'track_id = ? AND manually_overridden = 0',
      whereArgs: [trackId],
    );
  }
}
