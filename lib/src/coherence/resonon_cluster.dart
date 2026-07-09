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

  /// Die Substanz des Feldes: inkohärente Energie Σ aᵢ² - phaseninvariant.
  ///
  /// Dies ist die Größe, die ohne externen Input strikt monoton fällt
  /// (Dissipation frisst Substanz). Die kohärente energy() darf dagegen
  /// durch Synchronisation atmen: Kopplung ordnet Substanz, sie erzeugt
  /// keine - deshalb gilt stets energy() <= (Σ aᵢ)² (Cauchy-Schwarz).
  double substance() {
    return waves.fold(0.0, (sum, w) => sum + w.amplitude * w.amplitude);
  }

  /// ω₀ - die Grund-Phasengeschwindigkeit des Feldes. Physikalische
  /// Begründung der Eigenfrequenzen (angekündigt in V0.2, eingelöst in
  /// V0.3): jedes Frequenzband f ist eine laufende Mode auf S¹, deren
  /// Wellenberge mit gemeinsamer Phasengeschwindigkeit ω₀ wandern -
  /// ψ_f(θ,t) ~ cos(f·(θ - ω₀t) + θᵢ). Daraus folgt zwingend ωᵢ = f·ω₀:
  /// höhere Moden rotieren proportional schneller, KEIN freier Parameter
  /// pro Welle.
  static const double naturalFrequencyBase = 1.0;

  /// Der zentrale Zeitschritt der schnellen Dynamik (V0.3):
  ///
  /// 1. Amplituden zerfallen (Dissipation - ohne externen Input verliert
  ///    das Feld immer Substanz Σ aᵢ²). Verklungene Wellen verlassen das Feld.
  /// 2. Phasen folgen der erweiterten Kuramoto-Dynamik in Mean-Field-Form
  ///    PRO FREQUENZBAND, jetzt mit Eigenrotation:
  ///        θ̇ᵢ = ωᵢ + K · r_Band · sin(ψ_Band − θᵢ),   ωᵢ = f_i · ω₀
  ///    Matrixfrei und O(N): jede Phase spürt nur den Ordnungsparameter
  ///    ihres eigenen Bandes, nie eine globale Meta-Invariante. r(t)
  ///    emergiert aus dieser lokalen Kopplung - es steuert sie nicht
  ///    (siehe INPUT_002, Punkt 5). Bänder verschiedener Frequenz koppeln
  ///    nicht (orthogonale Moden, konsistent mit energy()).
  ///
  /// Da alle Wellen eines Bandes dasselbe ω tragen, ist die Eigenrotation
  /// innerhalb eines Bandes ein globaler Phasenfaktor: r_Band, energy()
  /// und Substanz bleiben exakt invariant, die Synchronisationsdynamik
  /// (Phasendifferenzen) ist unverändert. ZWISCHEN den Bändern erzeugt
  /// f·ω₀ dagegen fortlaufende Verstimmung - die Schwebung, die erst die
  /// Kaustik-Projektion sichtbar macht (Interferenz der Bänder im Raum).
  ///
  /// Exakte Gegenphase ist ein instabiles Gleichgewicht (r_Band = 0 -> keine
  /// Kraft); jeder neue Impuls bricht die Symmetrie.
  ResononCluster tick(OrbitTick orbitTick) {
    const fastDecayRate = 2.0; // deutlich schneller als MemoryState (träge Schicht)
    const couplingStrength = 4.0; // K - stark genug, um Dissipation lokal zu übertönen
    final dt = orbitTick.deltaTime;
    final decayFactor = math.exp(-fastDecayRate * dt);

    // Mean-Field pro Band aus dem AKTUELLEN Zustand (vor dem Schritt) -
    // alle Wellen sehen dasselbe Feld, die Reihenfolge bleibt bedeutungslos.
    final Map<int, List<Resonon>> bands = {};
    for (final w in waves) {
      bands.putIfAbsent(w.frequency, () => []).add(w);
    }
    final Map<int, ({double r, double meanPhase})> bandField = {};
    for (final entry in bands.entries) {
      double sumCos = 0.0;
      double sumSin = 0.0;
      for (final w in entry.value) {
        sumCos += math.cos(w.phase);
        sumSin += math.sin(w.phase);
      }
      final n = entry.value.length;
      bandField[entry.key] = (
        r: math.sqrt(sumCos * sumCos + sumSin * sumSin) / n,
        meanPhase: math.atan2(sumSin, sumCos),
      );
    }

    final evolved = <Resonon>[];
    for (final w in waves) {
      final newAmplitude = w.amplitude * decayFactor;
      if (newAmplitude < 1e-6) continue;

      final field = bandField[w.frequency]!;
      final omega = naturalFrequencyBase * w.frequency; // ωᵢ = f·ω₀
      final dTheta = (omega +
              couplingStrength * field.r * math.sin(field.meanPhase - w.phase)) *
          dt;
      final newPhase = (w.phase + dTheta) % (2 * math.pi);

      evolved.add(w.copyWith(amplitude: newAmplitude, phase: newPhase));
    }
    return ResononCluster(waves: evolved);
  }
}
