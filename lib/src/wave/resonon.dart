// lib/src/wave/resonon.dart

import 'dart:math' as math;

/// Die Quelle, aus der ein Resonon entspringt.
enum ResononSource {
  mouse,
  text,
  clock, // Wichtig für das neue Tick-System!
  sensor,
}

/// Ein unveränderliches Ereignis (Value Object) im Wellenfeld.
class Resonon {
  final int id;
  final DateTime timestamp;
  final int frequency; // Angesprochener Modus (Membran)
  final double amplitude; // Stärke des Impulses
  final double phase; // Verschiebung
  final ResononSource source;
  final Map<String, dynamic> metadata;

  const Resonon({
    required this.id,
    required this.timestamp,
    required this.frequency,
    required this.amplitude,
    required this.phase,
    required this.source,
    this.metadata = const {},
  });

  /// Evaluiert die Wellenamplitude an einem bestimmten Punkt Theta.
  double evaluate(double theta) {
    return amplitude * math.cos(frequency * theta + phase);
  }

  /// Erzeugt eine neue Resonanz mit modifizierter Amplitude/Phase.
  /// Identität (id, frequency, source, timestamp, metadata) bleibt erhalten -
  /// nur die schnelle Dynamik (Zerfall, Phasendrift) verändert sich pro Tick.
  Resonon copyWith({
    double? amplitude,
    double? phase,
  }) {
    return Resonon(
      id: id,
      timestamp: timestamp,
      frequency: frequency,
      amplitude: amplitude ?? this.amplitude,
      phase: phase ?? this.phase,
      source: source,
      metadata: metadata,
    );
  }
}
