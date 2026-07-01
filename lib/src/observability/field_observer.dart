// lib/src/observability/field_observer.dart

import '../resonance/field_state.dart';

/// Die abstrakte Basisklasse für alle Entitäten, die auf die
/// ungeschönte Physik des Orbits reagieren.
abstract class FieldObserver {
  const FieldObserver();

  /// Wird bei jedem System-Tick aufgerufen.
  /// Übergibt den exakten Zustand und die nicht-invasive Invarianz-Metrik.
  void onFieldEvolution(FieldState state, InvarianceMeta meta);
}
