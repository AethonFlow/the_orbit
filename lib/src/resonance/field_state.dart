// lib/src/resonance/field_state.dart

import '../coherence/conservation_relation.dart';
import '../coherence/formal_invariance_layer.dart';
import '../coherence/memory_state.dart';
import '../coherence/resonon_cluster.dart';
import '../wave/orbit_clock.dart';

/// Der vollständige Zustand des Resonanzfeldes.
/// Immutable - jeder Tick erzeugt einen neuen Zustand.
///
/// Trägt zwei Zeitskalen (cluster = schnell, memory = langsam) sowie die
/// Δ/Φ/Ω-Erhaltungsrelation. Der Default-Konstruktor beschreibt das
/// Vakuum: leeres Feld, volle Kohärenz, ruhende Erhaltungsrelation.
class FieldState {
  final ResononCluster cluster;
  final MemoryState memory;

  /// Globale Kohärenz (0.0 - 1.0), identisch mit dem Kuramoto r(t) des
  /// Clusters zum Zeitpunkt dieses Zustands.
  final double globalCoherence;

  /// Δ/Φ/Ω - die Erhaltungsrelation des Feldes.
  final ConservationRelation flowRelation;

  const FieldState({
    this.cluster = const ResononCluster(),
    this.memory = const MemoryState(),
    this.globalCoherence = 1.0,
    this.flowRelation =
        const ConservationRelation(delta: 0.0, phi: 1.0, omega: 0.0),
  });

  FieldState copyWith({
    ResononCluster? cluster,
    MemoryState? memory,
    double? globalCoherence,
    ConservationRelation? flowRelation,
  }) {
    return FieldState(
      cluster: cluster ?? this.cluster,
      memory: memory ?? this.memory,
      globalCoherence: globalCoherence ?? this.globalCoherence,
      flowRelation: flowRelation ?? this.flowRelation,
    );
  }

  /// Bequemlichkeits-Wrapper: nur den Cluster (schnelle Dynamik) ersetzen,
  /// z.B. direkt nach dem Einspeisen neuer externer Impulse.
  FieldState withCluster(ResononCluster newCluster) =>
      copyWith(cluster: newCluster);

  /// Nicht-invasive Invarianz-Metrik (r(t), ψ(t)) - rein abgeleitet,
  /// fließt niemals in tick() zurück.
  InvarianceMeta get invarianceMeta => InvarianceMeta.fromCluster(cluster);

  /// Der zentrale Lebenszyklus-Schritt: ehrliche, unmanipulierte Physik.
  /// Cluster zerfällt/rotiert (schnell), Memory relaxiert (langsam),
  /// globalCoherence wird aus dem neuen Cluster gemessen, und die
  /// Erhaltungsrelation trackt Φ der neuen Kohärenz nach.
  FieldState tick(OrbitTick orbitTick) {
    final newCluster = cluster.tick(orbitTick);
    final newMemory =
        memory.tick(orbitTick, fieldEnergy: newCluster.energy());
    final newCoherence = newCluster.coherence();
    final newFlow = flowRelation.next(
      incomingEnergy: 0.0,
      coherence: newCoherence,
      dt: orbitTick.deltaTime,
    );

    return FieldState(
      cluster: newCluster,
      memory: newMemory,
      globalCoherence: newCoherence,
      flowRelation: newFlow,
    );
  }
}
