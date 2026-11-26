/// Mesures brutes renvoyées par le module natif.
class RawFeatures {
  final double bpm;
  final double rhythmStrength; // 0..1 : régularité du rythme
  final double loudnessDb; // dBFS moyen
  final double dynamicRangeDb;
  final double centroidHz; // brillance du son

  const RawFeatures({
    required this.bpm,
    required this.rhythmStrength,
    required this.loudnessDb,
    required this.dynamicRangeDb,
    required this.centroidHz,
  });
}
