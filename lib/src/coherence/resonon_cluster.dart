// lib/src/coherence/resonon_cluster.dart

import 'dart:math' as math;

import '../wave/orbit_clock.dart';
import '../wave/resonon.dart';

/// Die schnelle Dynamik des Feldes: eine Menge aktiver Resonanzen (Wellen).
/// Unveränderlich (Value Object) - jede Operation erzeugt einen neuen Cluster.
///
/// Physikalisches Bild: jede Resonon ist ein komplexer Phasor
/// z_i = amplitude_i * e^(i * phase_i) auf ihrem Frequenzband. Energie und
/// Kohärenz entstehen NICHT aus der Summe der Einzelamplituden, sondern aus
/// der komplexwertigen Überlagerung - genau deshalb löschen sich zwei
/// identische, gegenphasige Wellen tatsächlich vollständig aus.
class ResononCluster {
  final List<Resonon> waves;

  const ResononCluster({this.waves = const []});

  int get activeWavesCount => waves.length;

  /// Fügt eine neue Resonanz zum Feld hinzu (reihenfolge-unabhängig).
  ResononCluster withResonon(Resonon resonon) {
    return ResononCluster(waves: [...waves, resonon]);
  }

  /// Feldwert an einem Punkt Theta - reine reelle Überlagerung aller Wellen.
  double psi(double theta) {
    if (waves.isEmpty) return 0.0;
    return waves.fold(0.0, (sum, w) => sum + w.evaluate(theta));
  }

  /// Energie des Feldes: pro Frequenzband werden die Wellen als komplexe
  /// Phasoren addiert (kohärente Überlagerung), das Betragsquadrat der
  /// Bandsummen wird über alle Bänder aufsummiert. Verschiedene Frequenzen
  /// interferieren nicht miteinander (orthogonale Moden), gleiche Frequenzen
  /// schon - inklusive vollständiger Auslöschung bei Gegenphase.
  double energy() {
    if (waves.isEmpty) return 0.0;

    final Map<int, List<Resonon>> bands = {};
    for (final w in waves) {
      bands.putIfAbsent(w.frequency, () => []).add(w);
    }

    double total = 0.0;
    for (final band in bands.values) {
      double real = 0.0;
      double imag = 0.0;
      for (final w in band) {
        real += w.amplitude * math.cos(w.phase);
        imag += w.amplitude * math.sin(w.phase);
      }
      total += real * real + imag * imag;
    }
    return total;
  }

  /// Globaler Kuramoto-Ordnungsparameter r*e^(iψ) = (1/N) Σ e^(iθ_j).
  /// r ∈ [0,1] misst reine Phasensynchronität (amplitudenunabhängig).
  /// Ein leeres Feld gilt als vollständig kohärent (Vakuum-Konvention,
  /// konsistent mit FieldState()'s Default globalCoherence = 1.0).
  ({double r, double meanPhase}) orderParameter() {
    if (waves.isEmpty) return (r: 1.0, meanPhase: 0.0);

    double sumCos = 0.0;
    double sumSin = 0.0;
    for (final w in waves) {
      sumCos += math.cos(w.phase);
      sumSin += math.sin(w.phase);
    }
    final n = waves.length;
    final r = math.sqrt(sumCos * sumCos + sumSin * sumSin) / n;
    final meanPhase = math.atan2(sumSin, sumCos);
    return (r: r, meanPhase: meanPhase);
  }

  double coherence() => orderParameter().r;

  /// Der zentrale Zeitschritt der schnellen Dynamik: Amplituden zerfallen
  /// (Dissipation - ohne externen Input verliert das Feld immer Energie).
  /// Phasen bleiben in V0.1 bewusst ruhend (noch keine freie Kuramoto-
  /// Rotation, noch kein Kopplungsterm) - reine, beobachtbare Dämpfung als
  /// erster Atemzug. Verklungene Wellen (Amplitude nahe Null) verlassen
  /// das Feld.
  ResononCluster tick(OrbitTick orbitTick) {
    const fastDecayRate = 2.0; // deutlich schneller als MemoryState (träge Schicht)
    final dt = orbitTick.deltaTime;
    final decayFactor = math.exp(-fastDecayRate * dt);

    final evolved = <Resonon>[];
    for (final w in waves) {
      final newAmplitude = w.amplitude * decayFactor;
      if (newAmplitude < 1e-6) continue;
      evolved.add(w.copyWith(amplitude: newAmplitude));
    }
    return ResononCluster(waves: evolved);
  }
}
