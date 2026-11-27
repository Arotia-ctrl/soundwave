import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../classification/domain/classifier.dart';
import '../../library/presentation/library_controller.dart';
import '../../settings/data/settings_controller.dart';
import '../data/analysis_repository.dart';
import '../data/native_analyzer.dart';
import '../domain/analysis_result.dart';

enum AnalysisPhase { idle, running, paused }

class AnalysisState {
  final Map<int, AnalysisResult> results;
  final AnalysisPhase phase;
  final int done;
  final int total;

  const AnalysisState({
    this.results = const {},
    this.phase = AnalysisPhase.idle,
    this.done = 0,
    this.total = 0,
  });

  AnalysisState copyWith({
    Map<int, AnalysisResult>? results,
    AnalysisPhase? phase,
    int? done,
    int? total,
  }) {
    return AnalysisState(
      results: results ?? this.results,
      phase: phase ?? this.phase,
      done: done ?? this.done,
      total: total ?? this.total,
    );
  }
}

final analysisRepositoryProvider = Provider<AnalysisRepository>(
  (ref) => AnalysisRepository(),
);

final nativeAnalyzerProvider = Provider<NativeAnalyzer>(
  (ref) => NativeAnalyzer(),
);

final analysisProvider = NotifierProvider<AnalysisController, AnalysisState>(
  AnalysisController.new,
);

class AnalysisController extends Notifier<AnalysisState> {
  bool _stopRequested = false;
  Future<void> _loadFuture = Future.value();

  AnalysisRepository get _repo => ref.read(analysisRepositoryProvider);

  @override
  AnalysisState build() {
    _loadFuture = Future.microtask(_load);
    return const AnalysisState();
  }

  Future<void> _load() async {
    try {
      state = state.copyWith(results: await _repo.loadAll());
    } catch (e) {
      debugPrint('Analyse : $e');
    }
  }

  static bool needsAnalysis(AnalysisResult? r) =>
      r == null || r.status == 'manual';

  /// Lance ou reprend l'analyse : seuls les morceaux sans résultat sont traités.
  Future<void> start() async {
    if (state.phase == AnalysisPhase.running) return;
    _stopRequested = false;
    state = state.copyWith(phase: AnalysisPhase.running, done: 0, total: 0);

    // Sans cette attente, un démarrage immédiat croirait que rien n'a été analysé
    await _loadFuture;

    final tracks = ref.read(libraryProvider).tracks;
    final pending = [
      for (final t in tracks)
        if (needsAnalysis(state.results[t.id])) t,
    ];
    if (pending.isEmpty) {
      state = state.copyWith(phase: AnalysisPhase.idle, done: 0, total: 0);
      return;
    }

    state = state.copyWith(total: pending.length);

    final native = ref.read(nativeAnalyzerProvider);
    var done = 0;

    for (final track in pending) {
      if (_stopRequested) break;
      try {
        final raw = await native.analyze(track.id);
        if (raw == null) {
          await _repo.saveFailure(track.id);
        } else {
          await _repo.saveAnalysis(track.id, raw, Classifier.classify(raw));
        }
      } catch (e) {
        debugPrint('Analyse de ${track.title} : $e');
        try {
          await _repo.saveFailure(track.id);
        } catch (_) {}
      }
      done++;

      AnalysisResult? fresh;
      try {
        fresh = await _repo.load(track.id);
      } catch (_) {}
      state = state.copyWith(
        results: fresh == null
            ? state.results
            : {...state.results, track.id: fresh},
        done: done,
      );
    }

    state = state.copyWith(
      phase: _stopRequested ? AnalysisPhase.paused : AnalysisPhase.idle,
    );
  }

  /// Termine le morceau en cours puis s'arrête.
  void pause() => _stopRequested = true;

  /// Supprime les échecs puis relance l'analyse sur ces morceaux.
  Future<void> retryFailed() async {
    if (state.phase == AnalysisPhase.running) return;
    try {
      await _repo.deleteFailed();
      state = state.copyWith(results: await _repo.loadAll());
    } catch (e) {
      debugPrint('Analyse : $e');
    }
    await start();
  }

  Future<void> _refresh(int trackId) async {
    try {
      final fresh = await _repo.load(trackId);
      final next = {...state.results};
      if (fresh == null) {
        next.remove(trackId);
      } else {
        next[trackId] = fresh;
      }
      state = state.copyWith(results: next);
    } catch (e) {
      debugPrint('Analyse : $e');
    }
  }

  Future<void> setManualMood(int trackId, Mood mood) async {
    try {
      await _repo.setManualMood(trackId, mood);
    } catch (e) {
      debugPrint('Analyse : $e');
    }
    await _refresh(trackId);
  }

  /// Rend la décision à l'analyse, sans redécoder le fichier.
  Future<void> clearManualMood(int trackId) async {
    try {
      final raw = state.results[trackId]?.rawFeatures;
      await _repo.clearManualMood(
        trackId,
        raw == null ? null : Classifier.classify(raw),
      );
    } catch (e) {
      debugPrint('Analyse : $e');
    }
    await _refresh(trackId);
  }

  /// Recalcule les catégories depuis les mesures déjà stockées (utile après
  /// un réglage des seuils). Les corrections manuelles sont conservées.
  Future<void> reclassifyAll() async {
    try {
      for (final r in state.results.values) {
        final raw = r.rawFeatures;
        if (r.analyzed && !r.manuallyOverridden && raw != null) {
          await _repo.updateClassification(r.trackId, Classifier.classify(raw));
        }
      }
      state = state.copyWith(results: await _repo.loadAll());
    } catch (e) {
      debugPrint('Analyse : $e');
    }
  }
}

/// Lance l'analyse toute seule quand l'option est activée dans Settings :
/// au démarrage, après un scan qui trouve de nouveaux morceaux, ou dès
/// l'activation de l'option. À surveiller une fois, en haut de l'application.
final autoAnalysisProvider = Provider<void>((ref) {
  void maybeStart() {
    if (!ref.read(settingsProvider).autoAnalysis) return;
    if (ref.read(libraryProvider).tracks.isEmpty) return;
    ref.read(analysisProvider.notifier).start();
  }

  ref.listen(libraryProvider.select((s) => s.tracks), (_, _) => maybeStart());
  ref.listen(
    settingsProvider.select((s) => s.autoAnalysis),
    (_, _) => maybeStart(),
  );
});
