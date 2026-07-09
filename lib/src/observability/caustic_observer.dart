// lib/src/observability/caustic_observer.dart

import '../coherence/formal_invariance_layer.dart';
import '../resonance/field_state.dart';
import 'field_observer.dart';
import 'radiance_projection.dart';

/// Ein einzelner Messpunkt der Kaustik-Zeitreihe.
///
/// [orderParameterR] und [brightness] sind ko-emergente Observablen
/// derselben Dynamik: keine steuert die andere, beide messen die
/// Synchronisation des Feldes - r(t) abstrakt im Phasenraum, die
/// Helligkeit konkret als Leuchten der Brennlinie im Beobachtungsraum.
class CausticSample {
  /// r(t) - der Kuramoto-Ordnungsparameter zum Zeitpunkt der Messung.
  final double orderParameterR;

  /// I(p_probe) - rohe Intensität am Messpunkt.
  final double intensity;

  /// I(p_probe) / Σa² - Helligkeit pro Substanz. Diese Normierung trennt
  /// die Ordnung (Synchronisation) vom Zerfall (Dissipation): sie wächst
  /// streng monoton mit der Synchronisation, obwohl die Substanz fällt.
  final double brightness;

  const CausticSample({
    required this.orderParameterR,
    required this.intensity,
    required this.brightness,
  });
}

/// Der erste konkrete Feld-Beobachter: hält bei jedem System-Tick die
/// Helligkeit der Kaustik an einem Messpunkt fest (Default: der Cusp der
/// Nephroide bei (-R/2, 0)) - zusammen mit dem emergenten r(t).
///
/// Vollständig nicht-invasiv im Sinne von ADR_001: liest FieldState und
/// InvarianceMeta, wirkt niemals zurück. Die Kern-Physik kennt weder die
/// Projektion noch diesen Beobachter.
///
/// Damit schließt sich der Bogen aus INPUT_002: Kuramoto-Kopplung (Kern)
/// erzeugt Synchronisation, die Projektion 𝒫 (Beobachtung) macht sie als
/// aufleuchtende Brennlinie sichtbar - Kohärenz ist keine Kennzahl mehr,
/// sondern ein messbares Leuchten.
class CausticObserver extends FieldObserver {
  final RadianceProjection projection;

  /// Der Messpunkt in der Beobachtungsebene.
  final FieldPoint probe;

  final List<CausticSample> _samples = [];

  /// Die aufgezeichnete Zeitreihe (unveränderliche Sicht).
  List<CausticSample> get samples => List.unmodifiable(_samples);

  CausticObserver({
    this.projection = const RadianceProjection(),
    FieldPoint? probe,
  }) : probe = probe ??
            (x: -0.5 * projection.shellRadius, y: 0.0); // Nephroiden-Cusp

  @override
  void onFieldEvolution(FieldState state, InvarianceMeta meta) {
    final substance = state.cluster.substance();
    final intensity = projection.intensityAt(state.cluster, probe);

    _samples.add(CausticSample(
      orderParameterR: meta.orderParameterR,
      intensity: intensity,
      brightness: substance > 1e-12 ? intensity / substance : 0.0,
    ));
  }
}
