// lib/src/observability/field_observer.dart

import '../coherence/formal_invariance_layer.dart';
import '../resonance/field_state.dart';
import '../wave/orbit_clock.dart';

/// Die Basisklasse für alle Entitäten, die auf die ungeschönte Physik des
/// Orbits reagieren. Konkret instanziierbar (V0.1) - onFieldEvolution() ist
/// ein reiner Hook, den konkrete Beobachter (UI, Audio, Logging) überschreiben.
///
/// Trägt außerdem die holografische Beobachtungsschicht: jeder abgetastete
/// Punkt einer Radiance-Topologie enthält eine vollständige Kopie der
/// globalen Feld-Invarianten - jeder Teil enthält das Ganze.
class FieldObserver {
  const FieldObserver();

  /// Wird bei jedem System-Tick aufgerufen.
  /// Übergibt den exakten Zustand und die nicht-invasive Invarianz-Metrik.
  void onFieldEvolution(FieldState state, InvarianceMeta meta) {
    // V0.1: kein Default-Verhalten - konkrete Beobachter überschreiben dies.
  }

  /// Misst, wie stark sich der Zustand zwischen zwei Ticks verschoben hat -
  /// die Summe der absoluten Verschiebung in Energie und Kohärenz. Immer
  /// >= 0, strikt > 0 sobald sich irgendetwas real verändert hat.
  double calculateStabilityGradient(FieldState oldState, FieldState newState) {
    final energyShift =
        (newState.cluster.energy() - oldState.cluster.energy()).abs();
    final coherenceShift =
        (newState.globalCoherence - oldState.globalCoherence).abs();
    return energyShift + coherenceShift;
  }

  /// Tastet das Feld holografisch an [resolution] Punkten ab. Jeder Punkt
  /// trägt dieselbe globale Signatur - eine echte Hologramm-Eigenschaft:
  /// jeder Teil (jedes "Haus") enthält das Ganze. Positionsabhängige
  /// Projektion (8-Häuser-Geometrie) ist der nächste Ausbauschritt.
  List<RadiancePoint> observeRadiance(FieldState state,
      {required int resolution}) {
    final meta = state.invarianceMeta;
    final fieldSignature = state.cluster.energy() + meta.orderParameterR;

    return List.generate(
      resolution,
      (_) => RadiancePoint(
        coherence: state.globalCoherence,
        phase: meta.meanPhase,
        fieldSignature: fieldSignature,
      ),
    );
  }

  /// Erkennt ein Ereignis zwischen zwei Zuständen anhand des
  /// Stabilitätsgradienten.
  FieldEvent detectEvent(
      FieldState oldState, FieldState newState, OrbitTick tick) {
    return FieldEvent(
      tick: tick,
      magnitude: calculateStabilityGradient(oldState, newState),
    );
  }
}

/// Ein einzelner holografischer Abtastpunkt des Feldes.
class RadiancePoint {
  final double coherence;
  final double phase;
  final double fieldSignature;

  const RadiancePoint({
    required this.coherence,
    required this.phase,
    required this.fieldSignature,
  });
}

/// Ein erkanntes Ereignis im Feld, verortet auf einem konkreten Tick.
class FieldEvent {
  final OrbitTick tick;
  final double magnitude;

  const FieldEvent({required this.tick, required this.magnitude});
}
