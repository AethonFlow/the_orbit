// lib/src/resonance/membrane.dart

import 'dart:math' as math;
import 'field_state.dart';

/// Die abstrakte Schnittstelle für alle Grenz-Organe des Systems.
/// Garantiert maximale Austauschbarkeit für zukünftige biologische Forschungsebenen.
abstract class Membrane {
  double get permeability;
  double get reflection;

  /// Passt sich rein an LOKALE Feldgrößen an (keine globalen Meta-Invarianzen!).
  void adaptGradients(double globalCoherence, double globalEnergy);

  MembraneExchange coConstruct({
    required double externalSignalMagnitude,
    required double currentCoherence,
  });
}

/// Die Osmotische Membran in ihrer ersten, evolutionären Reifestufe (V0.1).
/// Keine Pipeline, sondern ein reiner, lokaler Grenzprozess.
class OsmoticMembrane implements Membrane {
  final String id;
  double _permeability = 0.5;

  OsmoticMembrane({required this.id});

  @override
  double get permeability => _permeability;

  @override
  double get reflection => 1.0 - _permeability;

  @override
  void adaptGradients(double globalCoherence, double globalEnergy) {
    // Noesis-Korrektur: Reaktion NUR auf basale, lokale Kräfte des Systems.
    // Ein hochfrequentes, energiereiches Feld verformt die Grenze anders
    // als ein erstarrtes, hochkohärentes Feld.
    final double localGradient = globalEnergy - globalCoherence;

    // Reine, ungezwungene Sättigung ohne vorausschauende Kontrolllogik
    _permeability = 1.0 / (1.0 + math.exp(-localGradient * 3.0));
  }

  @override
  MembraneExchange coConstruct({
    required double externalSignalMagnitude,
    required double currentCoherence,
  }) {
    // Identität (Reflexion) und Austausch (Absorption) entstehen gleichzeitig.
    final double absorbed = externalSignalMagnitude * _permeability;
    final double reflected = externalSignalMagnitude * reflection;

    // Die Verformung der Phase im Moment des Übergangs (die Reibung an der Grenze)
    final double phaseShift = math.sin(currentCoherence) * reflection;

    return MembraneExchange(
      absorbedIntensity: absorbed,
      reflectedIdentity: reflected,
      boundaryPhaseShift: phaseShift,
    );
  }
}

/// Das Ergebnis der bidirektionalen Bedeutungsgleichung an der Grenze.
class MembraneExchange {
  final double absorbedIntensity; // Was diffundiert hinein?
  final double reflectedIdentity; // Was wird zurückgeworfen (Identität)?
  final double boundaryPhaseShift; // Wie verschiebt sich die Welle im Übergang?

  const MembraneExchange({
    required this.absorbedIntensity,
    required this.reflectedIdentity,
    required this.boundaryPhaseShift,
  });
}
