import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundwave/main.dart';

void main() {
  testWidgets('La navigation affiche les 5 sections', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SoundwaveApp()));

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
    await tester.pumpAndSettle();
    expect(find.text('Les réglages arrivent bientôt'), findsOneWidget);
  });
}
