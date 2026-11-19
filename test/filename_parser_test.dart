import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/features/metadata/domain/filename_parser.dart';

void main() {
  test('Extrait artiste et titre depuis le nom de fichier', () {
    final p = FilenameParser.parse('Ninho - Lettre à une femme.mp3');
    expect(p.artist, 'Ninho');
    expect(p.title, 'Lettre à une femme');
  });

  test('Ignore un numéro de piste', () {
    final p = FilenameParser.parse('03 - Ninho - Mamacita.mp3');
    expect(p.artist, 'Ninho');
    expect(p.title, 'Mamacita');
  });

  test('Sans séparateur : titre seul', () {
    final p = FilenameParser.parse('Mamacita.mp3');
    expect(p.artist, isNull);
    expect(p.title, 'Mamacita');
  });

  test('Les collaborations se regroupent sous l\'artiste principal', () {
    expect(FilenameParser.mainArtist('Ninho feat. Niska'), 'Ninho');
    expect(FilenameParser.mainArtist('Ninho ft Niska'), 'Ninho');
    expect(FilenameParser.mainArtist('Ninho'), 'Ninho');
  });
}
