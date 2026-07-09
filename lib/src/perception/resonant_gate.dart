// lib/src/perception/resonant_gate.dart

import 'dart:math' as math;

import '../coherence/resonon_cluster.dart';
import '../resonance/membrane.dart';
import '../wave/resonon.dart';

/// Organ 2 des Sensoriums (INPUT_003): Einlass wird nicht entschieden,
/// er emergiert.
///
/// Für einen Kandidaten mit Phase θ auf Band B mit lokalem Bandfeld
/// (r_B, ψ_B) gilt das Malus-Gesetz der Membran:
///
///     T = p_membran · [ ε + (1−ε) · ( (1−r_B)/2 + r_B · cos²((θ−ψ_B)/2) ) ]
///
/// - cos²(Δ/2): Resonanz-Transmission. Gleichphasig → voller Durchlass,
///   gegenphasig → Auslöschung an der Grenze. Zugehörigkeit ist
///   Interferenz, keine Regel.
/// - r_B interpoliert zwischen zwei Grenzfällen: ein synchronisiertes Band
///   (r_B → 1) ist maximal wählerisch (reines Malus-Gesetz), ein
///   chaotisches Band (r_B → 0) hat keine Identität, an der sich etwas
///   auslöschen könnte - es lässt ungerichtet die Hälfte von allem herein.
///   Identität und Selektivität sind dieselbe Größe.
/// - ε (Neugier-Leckstrom): ohne ihn hört das Feld nur noch, was es schon
///   singt - und verhungert, denn die Dissipation frisst Substanz und die
///   Suppe ist die Nahrung. ε > 0 gibt auch dem maximal Fremden eine
///   Stimme. Unbesetzte Bänder empfangen mit ε_nov: das Feld kann neue
///   Organe wachsen lassen.
///
/// Das Gate VEKTORISIERT die vorhandene OsmoticMembrane pro Band, statt
/// sie zu ersetzen (INPUT_002, Punkt 1): coConstruct() bleibt das skalare
/// Grenzorgan (Permeabilität, Phasenreibung), das Gate gibt ihm Phasenaugen.
///
/// Verfassungstreue (ADR_001 / INPUT_002 Punkt 5): liest ausschließlich
/// LOKALE Bandgrößen (r_B, ψ_B), niemals das globale r(t). Reine Funktion
/// Kandidaten × Feldzustand → Einlass; mutiert nichts, kein zentrales
/// Entscheidungsorgan.
class ResonantGate {
  final Membrane membrane;

  /// ε - Neugier-Leckstrom auf besetzten Bändern.
  final double curiosity;

  /// ε_nov - Durchlässigkeit unbesetzter Bänder (neue Organe).
  final double noveltyPermeability;

  /// Kandidaten, deren eingelassene Amplitude darunter fällt, verklingen
  /// an der Grenze.
  final double admissionFloor;

  ResonantGate({
    Membrane? membrane,
    this.curiosity = 0.15,
    this.noveltyPermeability = 0.3,
    this.admissionFloor = 1e-4,
  }) : membrane = membrane ?? OsmoticMembrane(id: 'sensorium');

  /// Lokales Bandfeld (r_B, ψ_B) eines Frequenzbandes - dieselbe
  /// Mean-Field-Größe, die auch tick() bandintern verwendet.
  static ({double r, double psi, bool occupied}) bandField(
      ResononCluster field, int frequency) {
    double sumCos = 0.0;
    double sumSin = 0.0;
    int n = 0;
    for (final w in field.waves) {
      if (w.frequency != frequency) continue;
      sumCos += math.cos(w.phase);
      sumSin += math.sin(w.phase);
      n++;
    }
    if (n == 0) return (r: 0.0, psi: 0.0, occupied: false);
    return (
      r: math.sqrt(sumCos * sumCos + sumSin * sumSin) / n,
      psi: math.atan2(sumSin, sumCos),
      occupied: true,
    );
  }

  /// Die Transmission T ∈ [0, 1] eines Kandidaten - vor der Membran-
  /// Permeabilität. Öffentlich, damit Beobachter dem Anklopfen zusehen
  /// können.
  double transmission(Resonon candidate, ResononCluster field) {
    final band = bandField(field, candidate.frequency);
    if (!band.occupied) return noveltyPermeability;
    final half = (candidate.phase - band.psi) / 2;
    final malus = math.cos(half) * math.cos(half);
    return curiosity +
        (1 - curiosity) * ((1 - band.r) / 2 + band.r * malus);
  }

  /// Osmose: lässt Kandidaten gemäß Resonanz ins Feld - abgeschwächt,
  /// phasenverschoben (Grenzreibung), oder gar nicht. Reine Funktion,
  /// [field] bleibt unberührt.
  List<Resonon> admit(List<Resonon> candidates, ResononCluster field) {
    final admitted = <Resonon>[];
    for (final c in candidates) {
      final band = bandField(field, c.frequency);
      final t = transmission(c, field);

      // Das skalare Grenzorgan wirkt weiter: Permeabilität und
      // Phasenreibung kommen aus coConstruct(), mit der LOKALEN
      // Band-Kohärenz als Kontext.
      final exchange = membrane.coConstruct(
        externalSignalMagnitude: c.amplitude * t,
        currentCoherence: band.r,
      );
      if (exchange.absorbedIntensity < admissionFloor) continue;

      admitted.add(c.copyWith(
        amplitude: exchange.absorbedIntensity,
        phase: (c.phase + exchange.boundaryPhaseShift) % (2 * math.pi),
      ));
    }
    return admitted;
  }
}
