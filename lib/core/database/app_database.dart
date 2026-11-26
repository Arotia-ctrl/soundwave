import 'package:sqflite/sqflite.dart';

/// Base locale de SOUNDWAVE. Les mises à jour futures passent par [_onUpgrade]
/// afin de ne jamais détruire les données de l'utilisateur.
class AppDatabase {
  AppDatabase._();

  static const int _version = 1;
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
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Exemple pour une future version 2 :
    // if (oldVersion < 2) {
    //   await db.execute('CREATE TABLE analysis_results (...)');
    // }
  }
}
