// lib/src/resonance/field_state.dart

import 'dart:math' as math;

import '../coherence/resonon_cluster.dart';
import '../coherence/conservation_relation.dart';
import '../coherence/formal_invariance_layer.dart';
import '../coherence/memory_state.dart';

/// Der vollständige Zustand des Resonanzfeldes.
/// Immutable – jeder Tick erzeugt einen neuen Zustand.
class FieldState {
  final ResononCluster cluster;
  final MemoryState memory;

  /// Globale Kohärenz (0.0 – 1.0)
  final double globalCoherence;

  /// Δ/Φ/Ω – die Erhaltungsrelation des Feldes
  final ConservationRelation flowRelation;

  const FieldState({
    required this.cluster,
    required this.memory,
    required this.globalCoherence,
    required this.flowRelation,
  });

  /// Erzeugt einen initialen, leeren Zustand
  factory FieldState.initial() {
    return FieldState(
      cluster: const ResononCluster(waves: []),
      memory: const MemoryState.initial(),
      globalCoherence: 1.0,
      flowRelation: const ConservationRelation(
        delta: 0.0,
        phi: 1.0,
        omega: 0.0,
      ),
    );
  }

  /// Externe Energie wird in die schnelle Dynamik eingespeist.
  /// Dies ist der zentrale Energie
