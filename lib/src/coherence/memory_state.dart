// lib/src/coherence/memory_state.dart

import 'dart:math' as math;

import '../wave/orbit_clock.dart';

/// Die langsame Dynamik des Feldes - das Gedächtnisfeld (Plastizität) aus
/// dem Zwiebelhaut-Modell (siehe ADR_001). Reagiert bewusst träger als der
/// ResononCluster (die schnelle Dynamik): je weiter innen, desto größer die
/// zeitliche Gravitation.
///
/// [elasticity] ist die aktuelle Formbarkeit des Gedächtnisses (1.0 = voll
/// plastisch, nimmt langsam ab). [layers] ist der Platzhalter für die
/// komprimierten Zyklen (Jahresringe) des logarithmischen
/// Zwiebelschalen-Prinzips - wird erst mit dem Kollaps-Übergang befüllt.
class MemoryState {
  final double elasticity;
  final List<double> layers;

  const MemoryState({this.elasticity = 1.0, this.layers = const []});

  MemoryState tick(OrbitTick orbitTick, {required double fieldEnergy}) {
    // Deutlich träger als ResononCluster._fastDecayRate (2.0) - das
    // Gedächtnis vergisst nicht im selben Atemzug wie die Welle zerfällt.
    const slowDecayRate = 0.1;
    final newElasticity =
        (elasticity * math.exp(-slowDecayRate * orbitTick.deltaTime))
            .clamp(0.0, 1.0).toDouble();

    return MemoryState(elasticity: newElasticity, layers: layers);
  }
}
