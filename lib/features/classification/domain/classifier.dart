import '../../analyzer/domain/raw_features.dart';

enum Mood {
  soft('soft', 'Soft'),
  nonSoft('non_soft', 'Non-soft'),
  uncertain('uncertain', 'À confirmer'),
  unknown('unknown', 'Unknown');

  final String db;
  final String label;
  const Mood(this.db, this.label);

  static Mood fromDb(String? value) =>
      Mood.values.firstWhere((m) => m.db == value, orElse: () => Mood.unknown);
}

enum TempoCategory {
  slow('slow', 'Slow'),
  fast('fast', 'Fast'),
  unknown('unknown', 'Unknown');

  final String db;
  final String label;
  const TempoCategory(this.db, this.label);

  static TempoCategory fromDb(String? value) => TempoCategory.values.firstWhere(
    (t) => t.db == value,
    orElse: () => TempoCategory.unknown,
  );
}

class Classification {
  final double energy; // 0..1
  final double softScore; // 0..1 (1 = très doux)
  final Mood mood;
  final TempoCategory tempo;
  final double confidence; // 0..1

  const Classification({
    required this.energy,
    required this.softScore,
    required this.mood,
    required this.tempo,
    required this.confidence,
  });
}

class Classifier {
  // ---- Réglages : valeurs de départ, à ajuster avec ta bibliothèque ----
  static const double slowBelowBpm = 100; // en dessous : Slow
  static const double minRhythmStrength = 0.05; // en dessous : tempo inconnu
  static const double softAtLeast = 0.55; // score >= : Soft
  static const double nonSoftAtMost = 0.35; // score <= : Non-soft
  // entre les deux : À confirmer

  static double _norm(double v, double lo, double hi) =>
      ((v - lo) / (hi - lo)).clamp(0.0, 1.0).toDouble();

  static Classification classify(RawFeatures f) {
    final loud = _norm(f.loudnessDb, -30, -8);
    final bright = _norm(f.centroidHz, 500, 2500);
    final energy = 0.6 * loud + 0.4 * bright;

    final bpmReliable = f.bpm > 0 && f.rhythmStrength >= minRhythmStrength;
    final tempo = !bpmReliable
        ? TempoCategory.unknown
        : (f.bpm < slowBelowBpm ? TempoCategory.slow : TempoCategory.fast);

    // Le BPM n'est qu'un indicateur parmi d'autres : neutre s'il n'est pas fiable
    final tempoSoft = bpmReliable ? _norm(125 - f.bpm, 0, 55) : 0.5;
    final dynamicSoft = _norm(f.dynamicRangeDb, 6, 18);

    final softScore =
        0.5 * (1 - energy) + 0.25 * tempoSoft + 0.25 * dynamicSoft;

    final Mood mood;
    if (softScore >= softAtLeast) {
      mood = Mood.soft;
    } else if (softScore <= nonSoftAtMost) {
      mood = Mood.nonSoft;
    } else {
      mood = Mood.uncertain;
    }

    final confidence = ((softScore - 0.45).abs() / 0.45)
        .clamp(0.0, 1.0)
        .toDouble();

    return Classification(
      energy: energy,
      softScore: softScore,
      mood: mood,
      tempo: tempo,
      confidence: confidence,
    );
  }
}
