// lib/src/resonance/resonance_engine.dart

import '../observability/field_observer.dart';
import '../wave/orbit_clock.dart';
import 'field_state.dart';

class ResonanceEngine {
  FieldState _currentState = const FieldState();
  final List<FieldObserver> _observers = [];

  FieldState get state => _currentState;

  /// Registriert einen neuen Beobachter (z.B. für UI-Fluktuationen oder Audio)
  void registerObserver(FieldObserver observer) {
    _observers.add(observer);
  }

  /// Entfernt einen Beobachter aus dem Feld
  void removeObserver(FieldObserver observer) {
    _observers.remove(observer);
  }

  /// Der zentrale Lebenszyklus-Schritt (Tick-Evolution)
  void step(OrbitTick tick) {
    // 1. Berechne die reine, unmanipulierte Physik (Ehrliche Feldtheorie)
    _currentState = _currentState.tick(tick);

    // 2. Informiere alle abgeleiteten Beobachter-Klassen völlig entkoppelt
    for (final observer in _observers) {
      observer.onFieldEvolution(_currentState, _currentState.invarianceMeta);
    }
  }
}
