// test/ri_orbit_test.dart

import 'package:test/test.dart';
import 'package:ri_orbit/ri_orbit.dart';
import 'dart:math' as math;

void main() {
  group('WaveField Invarianten (Noesis Protocol)', () {
    test('Leeres Feld muss absolute Nullenergie besitzen', () {
      const field = ResononCluster();
      expect(field.energy(), equals(0.0));
      expect(field.activeWavesCount, equals(0));
    });

    test('Ohne Input darf energy() durch tick() niemals zunehmen', () {
      final initialField = const ResononCluster().withResonon(
        Resonon(
          id: 1,
          timestamp: DateTime.now(),
          frequency: 3,
          amplitude: 2.5,
          phase: 0.0,
          source: ResononSource.text,
        ),
      );

      final energyBefore = initialField.energy();

      final tick = OrbitTick(
          sequenceNumber: 1, timestamp: DateTime.now(), deltaTime: 1.0);
      final decayedField = initialField.tick(tick);

      expect(decayedField.energy(), lessThan(energyBefore));
    });

    test('Die Reihenfolge des Hinzufügens darf das Endergebnis nicht verändern',
        () {
      final r1 = Resonon(
          id: 1,
          timestamp: DateTime.now(),
          frequency: 2,
          amplitude: 1.0,
          phase: 0.0,
          source: ResononSource.mouse);
      final r2 = Resonon(
          id: 2,
          timestamp: DateTime.now(),
          frequency: 5,
          amplitude: 0.5,
          phase: math.pi / 4,
          source: ResononSource.mouse);

      final fieldA = const ResononCluster().withResonon(r1).withResonon(r2);
      final fieldB = const ResononCluster().withResonon(r2).withResonon(r1);

      expect(fieldA.psi(1.0), closeTo(fieldB.psi(1.0), 1e-9));
      expect(fieldA.energy(), closeTo(fieldB.energy(), 1e-9));
    });

    test(
        'Zwei identische Wellen mit entgegengesetzter Phase müssen sich auslöschen',
        () {
      final r1 = Resonon(
          id: 1,
          timestamp: DateTime.now(),
          frequency: 3,
          amplitude: 1.0,
          phase: 0.0,
          source: ResononSource.mouse);
      final r2 = Resonon(
          id: 2,
          timestamp: DateTime.now(),
          frequency: 3,
          amplitude: 1.0,
          phase: math.pi,
          source: ResononSource.mouse);

      final field = const ResononCluster().withResonon(r1).withResonon(r2);

      expect(field.psi(0.0), closeTo(0.0, 1e-9));
      expect(field.psi(math.pi / 2), closeTo(0.0, 1e-9));
      expect(field.energy(), closeTo(0.0, 1e-9));
    });

    test(
        'Zwei Zeitskalen: Memory (langsam) muss träger reagieren als Cluster (schnell)',
        () {
      var state = const FieldState();

      final heavyWave = Resonon(
          id: 99,
          timestamp: DateTime.now(),
          frequency: 1,
          amplitude: 10.0,
          phase: 0.0,
          source: ResononSource.text);
      state = state.withCluster(state.cluster.withResonon(heavyWave));

      final energyImmediately = state.cluster.energy();
      final elasticityImmediately = state.memory.elasticity;

      final tick = OrbitTick(
          sequenceNumber: 1, timestamp: DateTime.now(), deltaTime: 0.1);
      state = state.tick(tick);

      expect(state.cluster.energy(), lessThan(energyImmediately));
      expect(state.memory.elasticity, lessThan(elasticityImmediately));
      expect(state.memory.elasticity, greaterThan(0.5));
    });

    test(
        '100-Schritte-Simulation: Das Feld muss stabil evolvieren und relaxieren',
        () {
      final engine = ResonanceEngine();
      var state = const FieldState();

      // 1. Phase: 50 Ticks lang stetige Impulse
      for (int i = 0; i < 50; i++) {
        final tick = OrbitTick(
            sequenceNumber: i, timestamp: DateTime.now(), deltaTime: 0.1);
        final pulse = Resonon(
          id: i,
          timestamp: DateTime.now(),
          frequency: 2,
          amplitude: 1.5,
          phase: i * 0.1,
          source: ResononSource.mouse,
        );

        state = engine
            .step(currentState: state, tick: tick, incomingResonons: [pulse]);
      }

      final energyAfterHeavyInput = state.cluster.energy();
      expect(energyAfterHeavyInput, greaterThan(0.0));

      // 2. Phase: 50 Ticks reiner Zerfall (Das Feld relaxiert)
      for (int i = 50; i < 100; i++) {
        final tick = OrbitTick(
            sequenceNumber: i, timestamp: DateTime.now(), deltaTime: 0.1);
        state = engine
            .step(currentState: state, tick: tick, incomingResonons: const []);
      }

      expect(state.cluster.energy(), lessThan(energyAfterHeavyInput));
    });

    test('Holografischer Observer-Vierklang nach Noesis-Schärfung', () {
      final engine = ResonanceEngine();
      final observer = const FieldObserver();

      var stateOld = const FieldState();

      final tick = OrbitTick(
          sequenceNumber: 1, timestamp: DateTime(2026, 6, 23), deltaTime: 0.1);
      final heavyPulse = Resonon(
          id: 77,
          timestamp: DateTime(2026, 6, 23),
          frequency: 2,
          amplitude: 8.0,
          phase: 0.0,
          source: ResononSource.text);

      var stateNew = engine.step(
          currentState: stateOld, tick: tick, incomingResonons: [heavyPulse]);

      final gradient = observer.calculateStabilityGradient(stateOld, stateNew);
      expect(gradient, greaterThan(0.0));

      final topology = observer.observeRadiance(stateNew, resolution: 8);
      expect(topology.length, equals(8));

      final masterSignature = topology.first.fieldSignature;

      for (var point in topology) {
        expect(point.coherence, equals(stateNew.globalCoherence));
        expect(point.fieldSignature, equals(masterSignature));
        expect(point.phase, equals(0.0));
      }

      final event = observer.detectEvent(stateOld, stateNew, tick);
      expect(event.tick.sequenceNumber, equals(1));
    });
  });
}
