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
}
