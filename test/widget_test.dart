import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/features/library/presentation/library_controller.dart';
import 'package:soundwave/features/scanner/data/scanner_service.dart';
import 'package:soundwave/main.dart';
import 'package:soundwave/shared/models/track.dart';

class FakeScanner implements ScannerService {
  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<List<Track>> scan() async => [];
}

void main() {
  testWidgets('La navigation affiche les 5 sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [scannerServiceProvider.overrideWithValue(FakeScanner())],
        child: const SoundwaveApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in [
      'Home',
      'Library',
      'Discover',
      'Playlists',
      'Settings',
    ]) {
      expect(find.text(label), findsWidgets);
    }

    await tester.tap(find.text('Settings').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Les réglages arrivent bientôt'), findsOneWidget);
  });
}
