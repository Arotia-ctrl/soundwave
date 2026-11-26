import '../../classification/domain/classifier.dart';
import 'raw_features.dart';

class AnalysisResult {
  final int trackId;
  final double? bpm;
  final double? energy;
  final double? loudness;
  final double? dynamicRange;
  final double? spectralCentroid;
  final double? rhythmStrength;
  final Mood mood;
  final TempoCategory tempo;
  final double? confidence;

  /// 'ok' (analysé), 'failed' (échec) ou 'manual' (catégorie fixée à la main
  /// avant toute analyse).
  final String status;
  final bool manuallyOverridden;

  const AnalysisResult({
    required this.trackId,
    required this.bpm,
    required this.energy,
    required this.loudness,
    required this.dynamicRange,
    required this.spectralCentroid,
    required this.rhythmStrength,
    required this.mood,
    required this.tempo,
    required this.confidence,
    required this.status,
    required this.manuallyOverridden,
  });

  bool get analyzed => status == 'ok';

  /// Mesures brutes d'origine, utiles pour recalculer la catégorie sans
  /// redécoder le fichier.
  RawFeatures? get rawFeatures {
    if (bpm == null ||
        rhythmStrength == null ||
        loudness == null ||
        dynamicRange == null ||
        spectralCentroid == null) {
      return null;
    }
    return RawFeatures(
      bpm: bpm!,
      rhythmStrength: rhythmStrength!,
      loudnessDb: loudness!,
      dynamicRangeDb: dynamicRange!,
      centroidHz: spectralCentroid!,
    );
  }

  factory AnalysisResult.fromRow(Map<String, Object?> r) {
    double? d(String key) => (r[key] as num?)?.toDouble();
    return AnalysisResult(
      trackId: r['track_id'] as int,
      bpm: d('bpm'),
      energy: d('energy'),
      loudness: d('loudness'),
      dynamicRange: d('dynamic_range'),
      spectralCentroid: d('spectral_centroid'),
      rhythmStrength: d('rhythm_strength'),
      mood: Mood.fromDb(r['mood'] as String?),
      tempo: TempoCategory.fromDb(r['tempo_category'] as String?),
      confidence: d('confidence'),
      status: r['analysis_status'] as String,
      manuallyOverridden: (r['manually_overridden'] as int) == 1,
    );
  }
}
