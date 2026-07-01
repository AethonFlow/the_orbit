// lib/src/wave/resonon_wave.dart

import 'dart:math' as math;

/// Eine reine mathematische Welle im Resonanzfeld.
/// Wird vom ResononCluster manipuliert (Amplitude, Phase, Frequenz).
/// Unveränderlich (Value Object) und minimal gehalten.
class ResononWave {
  /// Stärke der Welle (0.0 – 1.0)
  final double amplitude;

  /// Phase der Welle im Bereich 0..2π
  final double phase;

  /// Frequenz der Welle (0.0 – 1.0)
  final double frequency;

  const ResononWave({
    required this.amplitude,
    required this.phase,
    required this.frequency,
  });

  /// Erzeugt eine neue Welle mit modifizierten Parametern.
  ResononWave copyWith({
    double? amplitude,
    double? phase,
    double? frequency,
  }) {
    return ResononWave(
      amplitude: amplitude ?? this.amplitude,
      phase: phase ?? this.phase,
      frequency: frequency ?? this.frequency,
    );
  }

  /// Evaluiert die Welle an einem Punkt θ.
  /// Wird z.B. für Visualisierung oder Kohärenzberechnung genutzt.
  double evaluate(double theta) {
    return amplitude * math.cos(frequency * theta + phase);
  }
}
