class Track {
  static const String unknown = 'Unknown';

  final int id;
  final String filePath;
  final String fileName;
  final String title;
  final String artist;
  final String mainArtist;
  final String album;
  final String genre;
  final int durationMs;
  final int fileSize;
  final int dateAdded;
  final int dateModified;
  final String metadataSource;

  const Track({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.title,
    required this.artist,
    required this.mainArtist,
    required this.album,
    required this.genre,
    required this.durationMs,
    required this.fileSize,
    required this.dateAdded,
    required this.dateModified,
    required this.metadataSource,
  });
}
