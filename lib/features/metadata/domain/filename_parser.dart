class ParsedName {
  final String? artist;
  final String title;
  const ParsedName(this.artist, this.title);
}

class FilenameParser {
  /// "Ninho - Lettre à une femme.mp3" -> artiste: Ninho, titre: Lettre à une femme
  static ParsedName parse(String fileName) {
    var name = fileName;
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);

    name = name.replaceAll('_', ' ').trim();
    // Retire un numéro de piste en début de nom : "01 - ", "07. ", "3) "
    name = name.replaceFirst(RegExp(r'^\d{1,3}\s*[-.)]\s*'), '');

    final match = RegExp(r'\s+[-–—]\s+').firstMatch(name);
    if (match != null) {
      final artist = name.substring(0, match.start).trim();
      final title = name.substring(match.end).trim();
      if (artist.isNotEmpty && title.isNotEmpty) {
        return ParsedName(artist, title);
      }
    }
    return ParsedName(null, name);
  }

  /// "Ninho feat. Niska" -> "Ninho"
  static String mainArtist(String artist) {
    final separator = RegExp(
      r'\s+(feat\.?|ft\.?|featuring)\s+|\s*[\(\[]\s*(feat\.?|ft\.?)\s',
      caseSensitive: false,
    );
    final main = artist.split(separator).first.trim();
    return main.isEmpty ? artist : main;
  }
}
