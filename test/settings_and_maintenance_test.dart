import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/features/settings/data/data_maintenance_repository.dart';
import 'package:soundwave/features/settings/data/settings_controller.dart';

void main() {
  group('Réglages', () {
    test('Valeurs par défaut sans rien de sauvegardé', () {
      final s = AppSettings.fromMap({});
      expect(s.resumePlayback, isTrue);
      expect(s.historySeconds, 15);
      expect(s.autoAnalysis, isFalse);
    });

    test('Lecture des valeurs sauvegardées', () {
      final s = AppSettings.fromMap({
        AppSettings.keyResume: '0',
        AppSettings.keyHistorySeconds: '30',
        AppSettings.keyAutoAnalysis: '1',
      });
      expect(s.resumePlayback, isFalse);
      expect(s.historySeconds, 30);
      expect(s.autoAnalysis, isTrue);
    });

    test('Une durée invalide retombe sur 15 secondes', () {
      expect(
        AppSettings.fromMap({
          AppSettings.keyHistorySeconds: '7',
        }).historySeconds,
        15,
      );
      expect(
        AppSettings.fromMap({
          AppSettings.keyHistorySeconds: 'abc',
        }).historySeconds,
        15,
      );
    });
  });

  group('Données orphelines', () {
    test('Repère les identifiants absents de la bibliothèque', () {
      final orphans = DataMaintenanceRepository.findOrphans(
        {1, 2, 3, 4},
        {2, 4, 5},
      );
      expect(orphans, {1, 3});
    });

    test('Rien à nettoyer quand tout existe', () {
      expect(DataMaintenanceRepository.findOrphans({1, 2}, {1, 2, 3}), isEmpty);
    });
  });
}
