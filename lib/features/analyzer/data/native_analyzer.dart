import 'package:flutter/services.dart';

import '../domain/raw_features.dart';

class NativeAnalyzer {
  static const MethodChannel _channel = MethodChannel('soundwave/analyzer');

  /// Renvoie null si le morceau ne peut pas être analysé.
  Future<RawFeatures?> analyze(int trackId) async {
    final res = await _channel.invokeMapMethod<String, dynamic>('analyze', {
      'id': trackId,
    });
    if (res == null) return null;
    double v(String key) => (res[key] as num).toDouble();
    return RawFeatures(
      bpm: v('bpm'),
      rhythmStrength: v('rhythmStrength'),
      loudnessDb: v('loudnessDb'),
      dynamicRangeDb: v('dynamicRangeDb'),
      centroidHz: v('centroidHz'),
    );
  }
}
