import 'package:sqflite/sqflite.dart';

/// Base locale de SOUNDWAVE. Les mises à jour futures passent par [_onUpgrade]
/// afin de ne jamais détruire les données de l'utilisateur.
class AppDatabase {
  AppDatabase._();

  static const int _version = 3;
  static Future<Database>? _future;

  static Future<Database> get instance => _future ??= _open();

  static Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      '$dir/soundwave.db',
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static const String _analysisTable = '''
    CREATE TABLE analysis_results (
      track_id INTEGER PRIMARY KEY,
      bpm REAL,
      energy REAL,
      loudness REAL,
      dynamic_range REAL,
      spectral_centroid REAL,
      rhythm_strength REAL,
      mood TEXT NOT NULL,
      tempo_category TEXT NOT NULL,
      confidence REAL,
      analysis_status TEXT NOT NULL,
      manually_overridden INTEGER NOT NULL DEFAULT 0,
      analyzed_at INTEGER NOT NULL
    )
  ''';

  static const String _preferencesTable = '''
    CREATE TABLE user_preferences (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''';

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE playlists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE playlist_tracks (
        playlist_id INTEGER NOT NULL,
        track_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        PRIMARY KEY (playlist_id, track_id),
        FOREIGN KEY (playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE favorites (
        track_id INTEGER PRIMARY KEY,
        added_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE listening_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        track_id INTEGER NOT NULL,
        played_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_history_track ON listening_history(track_id)',
    );
    await db.execute(_analysisTable);
    await db.execute(_preferencesTable);
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(_analysisTable);
    }
    if (oldVersion < 3) {
      await db.execute(_preferencesTable);
    }
  }
}
