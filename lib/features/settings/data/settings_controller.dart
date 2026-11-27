import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'preferences_repository.dart';

class AppSettings {
  static const keyResume = 'settings.resume_playback';
  static const keyHistorySeconds = 'settings.history_seconds';
  static const keyAutoAnalysis = 'settings.auto_analysis';
  static const allowedHistorySeconds = [5, 15, 30];

  final bool resumePlayback;
  final int historySeconds;
  final bool autoAnalysis;

  const AppSettings({
    this.resumePlayback = true,
    this.historySeconds = 15,
    this.autoAnalysis = false,
  });

  factory AppSettings.fromMap(Map<String, String> map) {
    final seconds = int.tryParse(map[keyHistorySeconds] ?? '');
    return AppSettings(
      resumePlayback: map[keyResume] != '0',
      historySeconds: allowedHistorySeconds.contains(seconds) ? seconds! : 15,
      autoAnalysis: map[keyAutoAnalysis] == '1',
    );
  }

  AppSettings copyWith({
    bool? resumePlayback,
    int? historySeconds,
    bool? autoAnalysis,
  }) {
    return AppSettings(
      resumePlayback: resumePlayback ?? this.resumePlayback,
      historySeconds: historySeconds ?? this.historySeconds,
      autoAnalysis: autoAnalysis ?? this.autoAnalysis,
    );
  }
}

final preferencesRepositoryProvider = Provider<PreferencesRepository>(
  (ref) => PreferencesRepository(),
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  PreferencesRepository get _repo => ref.read(preferencesRepositoryProvider);

  @override
  AppSettings build() {
    Future.microtask(_load);
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      state = AppSettings.fromMap(await _repo.loadAll());
    } catch (e) {
      debugPrint('Réglages : $e');
    }
  }

  Future<void> setResumePlayback(bool value) => _update(
    state.copyWith(resumePlayback: value),
    {AppSettings.keyResume: value ? '1' : '0'},
  );

  Future<void> setHistorySeconds(int value) => _update(
    state.copyWith(historySeconds: value),
    {AppSettings.keyHistorySeconds: '$value'},
  );

  Future<void> setAutoAnalysis(bool value) => _update(
    state.copyWith(autoAnalysis: value),
    {AppSettings.keyAutoAnalysis: value ? '1' : '0'},
  );

  Future<void> _update(AppSettings next, Map<String, String> values) async {
    state = next;
    try {
      await _repo.setAll(values);
    } catch (e) {
      debugPrint('Réglages : $e');
    }
  }
}
