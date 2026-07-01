// lib/src/coherence/formal_invariance_layer.dart

import 'resonon_cluster.dart';

/// Nicht-invasive Invarianz-Metrik: rein abgeleitete Kenngrößen des Feldes,
/// die niemals in die Kern-Physik zurückwirken. FieldState.tick() kennt
/// InvarianceMeta nicht - sie wird ausschließlich für Beobachter (UI, Audio,
/// /observability) NACH der Evolution berechnet.
///
/// Trägt den globalen Ordnungsparameter r(t) der erweiterten
/// Kuramoto-Dynamik: r(t) ∈ [0,1] misst, wie synchron die Phasen aller
/// aktiven Resonanzen zueinander stehen.
class InvarianceMeta {
  /// r(t) - globaler Kuramoto-Ordnungsparameter (Phasensynchronität).
  final double orderParameterR;

  /// ψ(t) - mittlere Phase des Feldes (Argument des komplexen
  /// Ordnungsparameters r·e^(iψ)).
  final double meanPhase;

  const InvarianceMeta({
    required this.orderParameterR,
    required this.meanPhase,
  });

  factory InvarianceMeta.fromCluster(ResononCluster cluster) {
    final op = cluster.orderParameter();
    return InvarianceMeta(orderParameterR: op.r, meanPhase: op.meanPhase);
  }
}
