// lib/src/coherence/conservation_relation.dart

import 'dart:math' as math;

/// Die Δ/Φ/Ω-Erhaltungsrelation des Feldes (siehe ADR_001_FELD_ONTOLOGIE).
///
/// - Δ (delta):  äußere Differenzenergie - osmotischer Druck von außen
/// - Φ (phi):    innere Kopplung / Kohärenz-Trägheit der Membran
/// - Ω (omega):  Rückfaltungsrate - öffnet die Membran, sobald Δ die
///               innere Kopplung Φ übersteigt ("die Membran atmet")
///
/// Unveränderlich (Value Object). Reine, lokale Physik - keine globale
/// Kontrolllogik.
class ConservationRelation {
  final double delta;
  final double phi;
  final double omega;

  const ConservationRelation({
    required this.delta,
    required this.phi,
    required this.omega,
  });

  static const ConservationRelation initial = ConservationRelation(
    delta: 0.0,
    phi: 1.0,
    omega: 0.0,
  );

  /// Ein Zeitschritt der Erhaltungsrelation.
  /// [incomingEnergy] ist die von außen frisch eingespeiste Energie in diesem
  /// Tick (0.0 bei reinem Zerfall). [coherence] ist die aktuelle, gemessene
  /// Kohärenz des Clusters (r(t)), an die Φ sich träge angleicht.
  ConservationRelation next({
    required double incomingEnergy,
    required double coherence,
    required double dt,
  }) {
    // Φ folgt der Kohärenz mit Trägheit (kein Sprung, sondern ein Angleichen).
    const phiTrackingRate = 0.5;
    final newPhi =
        phi + (coherence - phi) * (1 - math.exp(-phiTrackingRate * dt));

    // Δ akkumuliert einströmende Energie und dissipiert selbst über die Zeit.
    const deltaDecayRate = 1.0;
    final newDelta = delta * math.exp(-deltaDecayRate * dt) + incomingEnergy;

    // Ω löst aus, sobald der osmotische Druck (Δ) die innere Kopplung (Φ)
    // übersteigt - die Membran öffnet sich wieder zum Atmen.
    final pressure = newDelta - newPhi;
    final newOmega = pressure > 0 ? 1.0 - math.exp(-pressure) : 0.0;

    return ConservationRelation(
      delta: newDelta,
      phi: newPhi.clamp(0.0, 1.0).toDouble(),
      omega: newOmega,
    );
  }
}
