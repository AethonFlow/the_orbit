// lib/src/resonance/resonance_engine.dart

import '../observability/field_observer.dart';
import '../wave/orbit_clock.dart';
import '../wave/resonon.dart';
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

  /// Der reine, funktionale Kern-Schritt: nimmt einen Zustand, einen Takt und
  /// externe Impulse entgegen und liefert den nächsten Zustand zurück - ohne
  /// versteckte Mutation. Die Physik bleibt so nachvollziehbar und isoliert
  /// testbar (siehe test/ri_orbit_test.dart).
  FieldState step({
    required FieldState currentState,
    required OrbitTick tick,
    required List<Resonon> incomingResonons,
  }) {
    // 1. Externe Impulse in die schnelle Dynamik einspeisen
    var injectedCluster = currentState.cluster;
    for (final resonon in incomingResonons) {
      injectedCluster = injectedCluster.withResonon(resonon);
    }

    // 2. Die reine, unmanipulierte Physik auswerten (Ehrliche Feldtheorie)
    final nextState = currentState.withCluster(injectedCluster).tick(tick);

    // 3. Alle abgeleiteten Beobachter-Klassen völlig entkoppelt informieren
    for (final observer in _observers) {
      observer.onFieldEvolution(nextState, nextState.invarianceMeta);
    }

    return nextState;
  }

  /// Bequemlichkeits-Wrapper für den zustandsbehafteten Live-Betrieb
  /// (z.B. UI-Loop): hält _currentState intern nach und liefert ihn zurück.
  FieldState advance(OrbitTick tick,
      {List<Resonon> incomingResonons = const []}) {
    _currentState = step(
      currentState: _currentState,
      tick: tick,
      incomingResonons: incomingResonons,
    );
    return _currentState;
  }
}
