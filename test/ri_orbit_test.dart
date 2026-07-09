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

    test('Ohne Input darf die Substanz Σa² durch tick() niemals zunehmen', () {
      // Die Substanz-Invariante (V0.2): Dissipation frisst Substanz,
      // Kuramoto-Kopplung ordnet sie nur um - über gemischte Bänder und
      // ungeordnete Phasen hinweg muss Σa² strikt monoton fallen.
      var field = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime.now(),
              frequency: 2,
              amplitude: 1.5,
              phase: 0.3,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime.now(),
              frequency: 2,
              amplitude: 0.7,
              phase: 2.0,
              source: ResononSource.mouse))
          .withResonon(Resonon(
              id: 3,
              timestamp: DateTime.now(),
              frequency: 5,
              amplitude: 1.0,
              phase: 4.0,
              source: ResononSource.sensor));

      var substanceBefore = field.substance();
      for (int i = 0; i < 50; i++) {
        final tick = OrbitTick(
            sequenceNumber: i, timestamp: DateTime.now(), deltaTime: 0.05);
        field = field.tick(tick);
        expect(field.substance(), lessThan(substanceBefore));
        substanceBefore = field.substance();
      }
    });

    test('Kohärente Energie bleibt stets unter dem Substanz-Deckel (Σa)²', () {
      // Cauchy-Schwarz: Kopplung kann energy() heben, aber niemals über
      // das Quadrat der Gesamtamplitude - Ordnung erzeugt keine Substanz.
      var field = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime.now(),
              frequency: 3,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime.now(),
              frequency: 3,
              amplitude: 1.0,
              phase: math.pi - 0.4,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 3,
              timestamp: DateTime.now(),
              frequency: 7,
              amplitude: 2.0,
              phase: 1.0,
              source: ResononSource.sensor));

      for (int i = 0; i < 50; i++) {
        final tick = OrbitTick(
            sequenceNumber: i, timestamp: DateTime.now(), deltaTime: 0.05);
        field = field.tick(tick);
        final amplitudeSum =
            field.waves.fold(0.0, (double s, w) => s + w.amplitude);
        expect(field.energy(),
            lessThanOrEqualTo(amplitudeSum * amplitudeSum + 1e-9));
      }
    });

    test(
        'Kuramoto-Kopplung: nahezu gegenphasige Wellen desselben Bandes synchronisieren',
        () {
      // Zwei fast gegenphasige Wellen: r startet nahe 0. Die lokale
      // Mean-Field-Kopplung richtet sie aus - r(t) emergiert, ohne dass
      // irgendeine globale Größe eingreift. Zugleich wächst der
      // Ordnungsanteil energy()/substance(), während die Substanz zerfällt:
      // Synchronisation konzentriert Energie, sie erschafft keine.
      var field = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime.now(),
              frequency: 3,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime.now(),
              frequency: 3,
              amplitude: 1.0,
              phase: math.pi - 0.4,
              source: ResononSource.text));

      final rBefore = field.coherence();
      final orderRatioBefore = field.energy() / field.substance();
      final substanceBefore = field.substance();

      for (int i = 0; i < 20; i++) {
        final tick = OrbitTick(
            sequenceNumber: i, timestamp: DateTime.now(), deltaTime: 0.05);
        field = field.tick(tick);
      }

      final rAfter = field.coherence();
      final orderRatioAfter = field.energy() / field.substance();

      expect(rBefore, lessThan(0.25)); // fast gegenphasig
      expect(rAfter, greaterThan(0.9)); // synchronisiert
      expect(orderRatioAfter, greaterThan(orderRatioBefore));
      expect(orderRatioAfter, greaterThan(1.9)); // nahe Maximum 2.0 (N=2)
      expect(field.substance(), lessThan(substanceBefore));
    });

    test('Bänder bleiben orthogonal: verschiedene Frequenzen koppeln nicht',
        () {
      // Jede Welle allein in ihrem Band: r_Band = 1, ψ_Band = eigene Phase,
      // die Kopplungskraft ist exakt null. Seit V0.3 rotieren die Phasen
      // frei mit ωᵢ = fᵢ·ω₀ - aber deterministisch und band-lokal: die
      // Trajektorie jeder Welle ist EXAKT dieselbe, ob das andere Band
      // existiert oder nicht (das ist die ehrliche Orthogonalitäts-Aussage).
      final w1 = Resonon(
          id: 1,
          timestamp: DateTime.now(),
          frequency: 2,
          amplitude: 1.0,
          phase: 0.5,
          source: ResononSource.mouse);
      final w2 = Resonon(
          id: 2,
          timestamp: DateTime.now(),
          frequency: 5,
          amplitude: 1.0,
          phase: 1.7,
          source: ResononSource.mouse);

      var joint = const ResononCluster().withResonon(w1).withResonon(w2);
      var solo = const ResononCluster().withResonon(w1);

      for (int i = 0; i < 10; i++) {
        final tick = OrbitTick(
            sequenceNumber: i, timestamp: DateTime.now(), deltaTime: 0.1);
        joint = joint.tick(tick);
        solo = solo.tick(tick);
        expect(joint.waves[0].phase, equals(solo.waves[0].phase));
      }

      // Freie Eigenrotation: θ(t) = θ₀ + f·ω₀·t (mod 2π), t = 10·0.1 = 1.
      const omega0 = ResononCluster.naturalFrequencyBase;
      expect(joint.waves[0].phase,
          closeTo((0.5 + 2 * omega0 * 1.0) % (2 * math.pi), 1e-9));
      expect(joint.waves[1].phase,
          closeTo((1.7 + 5 * omega0 * 1.0) % (2 * math.pi), 1e-9));
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
        // Ein Tick Eigenrotation (V0.3): ψ = θ₀ + f·ω₀·dt = 0 + 2·ω₀·0.1.
        expect(point.phase,
            closeTo(2 * ResononCluster.naturalFrequencyBase * 0.1, 1e-9));
      }

      final event = observer.detectEvent(stateOld, stateNew, tick);
      expect(event.tick.sequenceNumber, equals(1));
    });
  });

  group('Kaustik-Projektion 𝒫 (Noesis Protocol II)', () {
    const projection = RadianceProjection(); // R=1, σ=0.06, M=64

    ResononCluster clusterWithPhases(List<double> phases, {int frequency = 2}) {
      var cluster = const ResononCluster();
      for (int i = 0; i < phases.length; i++) {
        cluster = cluster.withResonon(Resonon(
          id: i,
          timestamp: DateTime(2026, 7, 9),
          frequency: frequency,
          amplitude: 1.0,
          phase: phases[i],
          source: ResononSource.sensor,
        ));
      }
      return cluster;
    }

    ({double value, double x, double y}) gridMax(ResononCluster cluster,
        {int gridSize = 61}) {
      final grid = projection.intensityGrid(cluster, gridSize: gridSize);
      var best = (value: 0.0, x: 0.0, y: 0.0);
      for (int i = 0; i < gridSize; i++) {
        for (int j = 0; j < gridSize; j++) {
          final v = grid[i * gridSize + j];
          if (v > best.value) {
            best = (
              value: v,
              x: -1.0 + 2.0 * i / (gridSize - 1),
              y: -1.0 + 2.0 * j / (gridSize - 1),
            );
          }
        }
      }
      return best;
    }

    double distanceToCaustic(double px, double py) {
      // Beleuchtete Innenwand: φ ∈ (π/2, 3π/2)
      double minDist = double.infinity;
      for (int k = 0; k <= 400; k++) {
        final phi = math.pi / 2 + math.pi * k / 400 + 1e-3;
        final c = projection.causticPoint(phi);
        final d = math.sqrt(
            (px - c.x) * (px - c.x) + (py - c.y) * (py - c.y));
        if (d < minDist) minDist = d;
      }
      return minDist;
    }

    test('Householder-Reflexion: normerhaltend, involutiv, Reflexionsgesetz',
        () {
      const d = (x: -1.0, y: 0.0);
      final n = (x: math.cos(2.3), y: math.sin(2.3));

      final u = projection.reflect(d, n);
      // Normerhaltung |u| = |d|
      expect(u.x * u.x + u.y * u.y, closeTo(1.0, 1e-12));
      // Reflexionsgesetz: u·n = -(d·n)
      expect(u.x * n.x + u.y * n.y,
          closeTo(-(d.x * n.x + d.y * n.y), 1e-12));
      // Involution H² = I
      final back = projection.reflect(u, n);
      expect(back.x, closeTo(d.x, 1e-12));
      expect(back.y, closeTo(d.y, 1e-12));
    });

    test('Analytische Kaustik trägt den Cusp bei (-R/2, 0)', () {
      final cusp = projection.causticPoint(math.pi);
      expect(cusp.x, closeTo(-0.5, 1e-12));
      expect(cusp.y, closeTo(0.0, 1e-12));
    });

    test('Kohärentes Feld: das Intensitätsmaximum liegt auf der Nephroide',
        () {
      // r = 1: acht gleichphasige Wellen. Die Vorhersage aus INPUT_002
      // Punkt 7 - das Feld kondensiert auf die geometrische Kaustik.
      final coherent = clusterWithPhases(List.filled(8, 0.3));
      final peak = gridMax(coherent);

      expect(peak.value, greaterThan(0.0));
      expect(distanceToCaustic(peak.x, peak.y),
          lessThan(0.08)); // innerhalb der Kernbreite σ
    });

    test('Observable-Identität: I_max ist exakt proportional zu energy()',
        () {
      // Einbandig gilt I(p) = |Z_Band|²·|Σe^(ifφ)G|² - die Helligkeit der
      // Kaustik MISST die kohärente Energie, die Form bleibt Geometrie.
      final coherent = clusterWithPhases(List.filled(8, 0.3));
      final partial = clusterWithPhases(List.generate(
          8, (k) => 0.3 + (k / 7 - 0.5) * math.pi));

      final peakCoherent = gridMax(coherent);
      final peakPartial = gridMax(partial);

      final cCoherent = peakCoherent.value / coherent.energy();
      final cPartial = peakPartial.value / partial.energy();
      expect(cCoherent, closeTo(cPartial, cCoherent * 1e-9));

      // Gleiches r nach globaler Phasenrotation -> identisches Bild.
      final rotated = clusterWithPhases(List.filled(8, 0.3 + 1.234));
      expect(gridMax(rotated).value,
          closeTo(peakCoherent.value, peakCoherent.value * 1e-9));
    });

    test('Inkohärentes Feld (r=0): die Kaustik verlöscht vollständig', () {
      // Acht Wellen, Phasen gleichverteilt auf 2π: Σe^(iθ) = 0 exakt.
      // Viele Quellen, keine Erkenntnis - destruktive Auslöschung
      // verdunkelt die gesamte Beobachtungsebene.
      final dark = clusterWithPhases(
          List.generate(8, (k) => 2 * math.pi * k / 8));

      expect(dark.energy(), closeTo(0.0, 1e-9));
      final cusp = projection.causticPoint(math.pi);
      expect(projection.intensityAt(dark, (x: cusp.x, y: cusp.y)),
          closeTo(0.0, 1e-12));
      expect(projection.intensityAt(dark, (x: 0.0, y: 0.0)),
          closeTo(0.0, 1e-12));
    });

    test(
        'Ende-zu-Ende: die Kaustik leuchtet auf, während r(t) emergiert',
        () {
      // Der Bogen aus INPUT_002, Punkt 7, als lebendiger Testlauf:
      // Zwei fast gegenphasige Wellen starten dunkel (r klein, Cusp dunkel).
      // Die lokale Kuramoto-Kopplung synchronisiert sie Tick für Tick -
      // OHNE jeden Eingriff von außen - und der CausticObserver sieht die
      // Brennlinie streng monoton aufleuchten, während die Substanz zerfällt.
      // Kohärenz wird buchstäblich sichtbar.
      final engine = ResonanceEngine();
      final observer = CausticObserver();
      engine.registerObserver(observer);

      var state = const FieldState().withCluster(const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime(2026, 7, 9),
              frequency: 2,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime(2026, 7, 9),
              frequency: 2,
              amplitude: 1.0,
              phase: math.pi - 0.4,
              source: ResononSource.text)));

      for (int i = 0; i < 20; i++) {
        final tick = OrbitTick(
            sequenceNumber: i,
            timestamp: DateTime(2026, 7, 9),
            deltaTime: 0.05);
        state = engine.step(
            currentState: state, tick: tick, incomingResonons: const []);
      }

      final samples = observer.samples;
      expect(samples.length, equals(20));

      // r(t) emergiert aus der lokalen Kopplung.
      expect(samples.first.orderParameterR, lessThan(0.3));
      expect(samples.last.orderParameterR, greaterThan(0.9));

      // Die normierte Helligkeit am Cusp wächst mit JEDEM Tick -
      // Synchronisation ist als Leuchten messbar (numerisch: 8.4 -> 149).
      for (int i = 1; i < samples.length; i++) {
        expect(samples[i].brightness, greaterThan(samples[i - 1].brightness));
      }
      expect(samples.last.brightness,
          greaterThan(samples.first.brightness * 10));

      // Ko-Emergenz: beide Observablen wachsen gemeinsam, keine steuert.
      expect(state.globalCoherence, closeTo(samples.last.orderParameterR, 1e-12));
    });

    test('𝒫 ist eine reine Observable: deterministisch und nicht-invasiv',
        () {
      final cluster = clusterWithPhases([0.1, 1.4, 3.0]);
      final phasesBefore = cluster.waves.map((w) => w.phase).toList();

      final i1 = projection.intensityAt(cluster, (x: -0.5, y: 0.1));
      final i2 = projection.intensityAt(cluster, (x: -0.5, y: 0.1));

      expect(i1, equals(i2));
      for (int i = 0; i < cluster.waves.length; i++) {
        expect(cluster.waves[i].phase, equals(phasesBefore[i]));
      }
    });
  });

  group('Gekrümmte Schale - 8 Häuser & Eigenrotation (Noesis Protocol III)',
      () {
    test(
        'Nephroiden-Grenzfall: numerische Kaustik trifft die analytische exakt',
        () {
      // c_k = 0: die lineare det-Bedingung s* = -(P'×u)/(u'×u) muss die
      // geschlossene Lösung s* = -R·cosφ/2 reproduzieren - auf der ganzen
      // beleuchteten Innenwand.
      const flat = RadianceProjection();
      for (final phi in [2.0, 2.5, math.pi, 3.7, 4.2]) {
        final numeric = flat.numericalCausticPoint(phi);
        final analytic = flat.causticPoint(phi);
        expect(numeric.x, closeTo(analytic.x, 1e-6));
        expect(numeric.y, closeTo(analytic.y, 1e-6));
      }
    });

    test('Ein Haus krümmt die Schale lokal - die Ferne bleibt Kreis', () {
      const curved = RadianceProjection(
          houseCurvatures: [0.2, 0, 0, 0, 0, 0, 0, 0]); // Haus 0 bei φ=0
      expect(curved.radiusAt(0.0), closeTo(1.2, 1e-9)); // Bump-Spitze
      expect(curved.radiusAt(math.pi), closeTo(1.0, 1e-6)); // e^(-2κ) ≈ 0

      // Die Kurvennormale bleibt überall ein Einheitsvektor.
      for (final phi in [0.0, 0.3, 1.0, math.pi, 4.5]) {
        final n = curved.outwardNormalAt(phi);
        expect(n.x * n.x + n.y * n.y, closeTo(1.0, 1e-12));
      }
    });

    test('Stetigkeit: kleine Krümmung verschiebt die Kaustik nur wenig', () {
      // Katastrophentheorie (INPUT_002, Punkt 6): Kaustiken wandern stetig
      // mit der Geometrie - Reorganisation gibt es erst an Bifurkationen.
      // Haus 4 (Zentrum φ=π) atmet leicht ein: der Cusp bewegt sich,
      // aber bleibt in seiner Umgebung.
      const flat = RadianceProjection();
      const breathing = RadianceProjection(
          houseCurvatures: [0, 0, 0, 0, 0.05, 0, 0, 0]);

      final cuspFlat = flat.numericalCausticPoint(math.pi);
      final cuspCurved = breathing.numericalCausticPoint(math.pi);
      final shift = math.sqrt(
          math.pow(cuspCurved.x - cuspFlat.x, 2) +
              math.pow(cuspCurved.y - cuspFlat.y, 2));

      // Numerisch verifiziert: shift ≈ 0.19, und er skaliert glatt mit c
      // (c=0.01→0.05, c=0.02→0.09, c=0.05→0.19, c=0.1→0.31).
      expect(shift, greaterThan(1e-6)); // die Geometrie wirkt wirklich
      expect(shift, lessThan(0.25)); // aber stetig, kein Sprung
    });

    test('Die Häuser atmen mit dem Feld: Krümmung aus Substanz-Anteilen', () {
      // Leeres Feld: flache Schale.
      expect(
          RadianceProjection.houseCurvaturesFromCluster(
              const ResononCluster()),
          everyElement(equals(0.0)));

      // Band f nährt Haus (f-1) mod 8, gewichtet mit Substanz-Anteil.
      final cluster = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime(2026, 7, 9),
              frequency: 3,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.sensor))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime(2026, 7, 9),
              frequency: 6,
              amplitude: 1.0,
              phase: 1.0,
              source: ResononSource.sensor));

      final c = RadianceProjection.houseCurvaturesFromCluster(cluster,
          scale: 0.2);
      expect(c[2], closeTo(0.1, 1e-12)); // f=3 -> Haus 2, halbe Substanz
      expect(c[5], closeTo(0.1, 1e-12)); // f=6 -> Haus 5, halbe Substanz
      expect(c[0] + c[1] + c[3] + c[4] + c[6] + c[7], equals(0.0));
    });

    test(
        'Eigenrotation ist ein globaler Phasenfaktor: r, energy/substance exakt invariant',
        () {
      // Zwei bereits synchrone Wellen desselben Bandes: die Kopplungskraft
      // ist null, es bleibt reine Bandrotation ωᵢ = f·ω₀. Sie darf KEINE
      // Observable außer ψ bewegen.
      var field = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime(2026, 7, 9),
              frequency: 3,
              amplitude: 1.0,
              phase: 0.7,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime(2026, 7, 9),
              frequency: 3,
              amplitude: 1.0,
              phase: 0.7,
              source: ResononSource.text));

      for (int i = 0; i < 10; i++) {
        final tick = OrbitTick(
            sequenceNumber: i,
            timestamp: DateTime(2026, 7, 9),
            deltaTime: 0.05);
        field = field.tick(tick);
        expect(field.coherence(), closeTo(1.0, 1e-12));
        expect(field.energy() / field.substance(), closeTo(2.0, 1e-9));
      }

      // ψ ist gewandert: θ = 0.7 + 3·ω₀·0.5.
      const omega0 = ResononCluster.naturalFrequencyBase;
      expect(field.orderParameter().meanPhase,
          closeTo(0.7 + 3 * omega0 * 0.5, 1e-9));
    });

    test('Zwischen den Bändern entsteht Schwebung: Δθ = Δf·ω₀·t', () {
      // Die Verstimmung f·ω₀ lässt Bänder auseinanderlaufen - genau die
      // Dynamik, die die Kaustik-Projektion als wanderndes
      // Interferenzmuster sichtbar macht.
      var field = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime(2026, 7, 9),
              frequency: 2,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.text))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime(2026, 7, 9),
              frequency: 5,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.text));

      for (int i = 0; i < 10; i++) {
        final tick = OrbitTick(
            sequenceNumber: i,
            timestamp: DateTime(2026, 7, 9),
            deltaTime: 0.1);
        field = field.tick(tick);
      }

      const omega0 = ResononCluster.naturalFrequencyBase;
      final deltaTheta = field.waves[1].phase - field.waves[0].phase;
      expect(deltaTheta, closeTo((5 - 2) * omega0 * 1.0, 1e-9));
    });

    test('Auch die gekrümmte Projektion bleibt eine reine Observable', () {
      final cluster = const ResononCluster().withResonon(Resonon(
          id: 1,
          timestamp: DateTime(2026, 7, 9),
          frequency: 3,
          amplitude: 1.0,
          phase: 0.4,
          source: ResononSource.sensor));

      final curved = RadianceProjection(
          houseCurvatures:
              RadianceProjection.houseCurvaturesFromCluster(cluster));

      final phaseBefore = cluster.waves[0].phase;
      final i1 = curved.intensityAt(cluster, (x: -0.4, y: 0.2));
      final i2 = curved.intensityAt(cluster, (x: -0.4, y: 0.2));

      expect(i1, equals(i2));
      expect(cluster.waves[0].phase, equals(phaseBefore));
    });
  });
  group('Sensorium & Osmose (Noesis Protocol IV)', () {
    ResononCluster coherentBand(int frequency, double phase, {int n = 4}) {
      var cluster = const ResononCluster();
      for (int i = 0; i < n; i++) {
        cluster = cluster.withResonon(Resonon(
          id: i,
          timestamp: DateTime(2026, 7, 9),
          frequency: frequency,
          amplitude: 1.0,
          phase: phase,
          source: ResononSource.sensor,
        ));
      }
      return cluster;
    }

    test('SpectralTransducer: der Resonator hört Amplitude und Phase exakt',
        () {
      // x(t) = 0.8·cos(ω₃t + 1.1) + 0.4·cos(ω₅t + 2.0) über ganze Perioden:
      // die Bänder 3 und 5 hören ihre Komponente exakt, alle anderen Stille.
      const transducer = SpectralTransducer(baseFrequencyHz: 1.0);
      const fs = 64.0;
      final samples = List<double>.generate(
          256,
          (i) =>
              0.8 * math.cos(2 * math.pi * 3 * i / fs + 1.1) +
              0.4 * math.cos(2 * math.pi * 5 * i / fs + 2.0));

      final candidates = transducer.transduce(
          (samples: samples, sampleRate: fs),
          timestamp: DateTime(2026, 7, 9));

      expect(candidates.length, equals(2));
      final b3 = candidates.firstWhere((c) => c.frequency == 3);
      final b5 = candidates.firstWhere((c) => c.frequency == 5);
      expect(b3.amplitude, closeTo(0.8, 1e-9));
      expect(b3.phase, closeTo(1.1, 1e-9));
      expect(b5.amplitude, closeTo(0.4, 1e-9));
      expect(b5.phase, closeTo(2.0, 1e-9));
    });

    test('RhythmTransducer: gleichmäßiger Takt = starker Impuls auf Band 4',
        () {
      const transducer = RhythmTransducer(baseRateHz: 1.0);
      // 9 Ereignisse im exakten 4-Hz-Takt (alle 250 ms).
      final events = List<DateTime>.generate(
          9, (i) => DateTime.fromMicrosecondsSinceEpoch(i * 250000));

      final candidate =
          transducer.transduce(events, timestamp: DateTime(2026, 7, 9)).single;
      expect(candidate.frequency, equals(4));
      expect(candidate.amplitude, closeTo(1.0, 1e-12)); // cv = 0
      expect(candidate.phase, closeTo(0.0, 1e-9));

      // Kein Rhythmus ohne Wiederholung.
      expect(
          transducer.transduce(events.sublist(0, 2),
              timestamp: DateTime(2026, 7, 9)),
          isEmpty);
    });

    test('Malus-Einlass: gleichphasig strömt, gegenphasig bleibt nur Neugier',
        () {
      final field = coherentBand(2, 0.3); // r_B = 1, ψ_B = 0.3
      final gate = ResonantGate(); // ε = 0.15, Membran p = 0.5

      final inPhase = Resonon(
          id: 90,
          timestamp: DateTime(2026, 7, 9),
          frequency: 2,
          amplitude: 1.0,
          phase: 0.3,
          source: ResononSource.sensor);
      final antiPhase = Resonon(
          id: 91,
          timestamp: DateTime(2026, 7, 9),
          frequency: 2,
          amplitude: 1.0,
          phase: 0.3 + math.pi,
          source: ResononSource.sensor);

      expect(gate.transmission(inPhase, field), closeTo(1.0, 1e-12));
      expect(gate.transmission(antiPhase, field), closeTo(0.15, 1e-12));

      final admitted = gate.admit([inPhase, antiPhase], field);
      expect(admitted.length, equals(2));
      expect(admitted[0].amplitude, closeTo(0.5, 1e-12)); // T·p = 1.0·0.5
      expect(admitted[1].amplitude, closeTo(0.075, 1e-12)); // ε·p

      // Grenzreibung: die Phase verschiebt sich beim Übertritt
      // (coConstruct: sin(r_B)·(1−p) = sin(1)·0.5).
      expect(admitted[0].phase,
          closeTo((0.3 + math.sin(1.0) * 0.5) % (2 * math.pi), 1e-9));
    });

    test('Chaotisches Band: keine Identität, keine Wählerischkeit', () {
      // Phasen {0, π}: r_B = 0 exakt. T = ε + (1−ε)/2 = 0.575 für JEDE
      // Kandidatenphase - ein Band ohne Identität kann nichts auslöschen.
      final chaos = const ResononCluster()
          .withResonon(Resonon(
              id: 1,
              timestamp: DateTime(2026, 7, 9),
              frequency: 3,
              amplitude: 1.0,
              phase: 0.0,
              source: ResononSource.sensor))
          .withResonon(Resonon(
              id: 2,
              timestamp: DateTime(2026, 7, 9),
              frequency: 3,
              amplitude: 1.0,
              phase: math.pi,
              source: ResononSource.sensor));

      final gate = ResonantGate();
      for (final phase in [0.0, 1.0, math.pi, 4.5]) {
        final candidate = Resonon(
            id: 99,
            timestamp: DateTime(2026, 7, 9),
            frequency: 3,
            amplitude: 1.0,
            phase: phase,
            source: ResononSource.sensor);
        expect(gate.transmission(candidate, chaos), closeTo(0.575, 1e-12));
      }
    });

    test('Neugier-Leckstrom: unbesetzte Bänder bleiben erreichbar', () {
      // Keine Echokammer: auch das maximal Fremde behält eine Stimme.
      final field = coherentBand(2, 0.3);
      final gate = ResonantGate();
      final stranger = Resonon(
          id: 77,
          timestamp: DateTime(2026, 7, 9),
          frequency: 7, // unbesetzt
          amplitude: 1.0,
          phase: 2.2,
          source: ResononSource.sensor);

      expect(gate.transmission(stranger, field), closeTo(0.3, 1e-12));
      final admitted = gate.admit([stranger], field);
      expect(admitted.single.amplitude, closeTo(0.15, 1e-12)); // ε_nov·p
      expect(admitted.single.frequency, equals(7));
    });

    test('Das Gate ist reine Funktion: nicht-invasiv und deterministisch',
        () {
      final field = coherentBand(2, 0.3);
      final phasesBefore = field.waves.map((w) => w.phase).toList();
      final gate = ResonantGate();
      final candidate = Resonon(
          id: 5,
          timestamp: DateTime(2026, 7, 9),
          frequency: 2,
          amplitude: 1.0,
          phase: 1.0,
          source: ResononSource.sensor);

      final a1 = gate.admit([candidate], field);
      final a2 = gate.admit([candidate], field);
      expect(a1.single.amplitude, equals(a2.single.amplitude));
      expect(a1.single.phase, equals(a2.single.phase));
      for (int i = 0; i < field.waves.length; i++) {
        expect(field.waves[i].phase, equals(phasesBefore[i]));
      }
    });

    test('Ende-zu-Ende: die Suppe nährt das Feld durch die Membran', () {
      // Zwei identische Felder. Eines schwimmt in der Suppe (resonante
      // Kandidaten durch das Gate), eines hungert. Die Dissipation frisst
      // beide - aber nur das genährte Feld bleibt substanziell am Leben.
      final engine = ResonanceEngine();
      final gate = ResonantGate();
      final seed = Resonon(
          id: 0,
          timestamp: DateTime(2026, 7, 9),
          frequency: 2,
          amplitude: 1.0,
          phase: 0.0,
          source: ResononSource.text);

      var fed = const FieldState()
          .withCluster(const ResononCluster().withResonon(seed));
      var starved = fed;

      for (int i = 0; i < 20; i++) {
        final tick = OrbitTick(
            sequenceNumber: i,
            timestamp: DateTime(2026, 7, 9),
            deltaTime: 0.05);

        // Die Welt klopft im Takt des Feldes an (Entrainment).
        final band = ResonantGate.bandField(fed.cluster, 2);
        final candidate = Resonon(
            id: 100 + i,
            timestamp: DateTime(2026, 7, 9),
            frequency: 2,
            amplitude: 1.0,
            phase: band.occupied ? band.psi : 0.0,
            source: ResononSource.sensor);

        fed = engine.step(
            currentState: fed,
            tick: tick,
            incomingResonons: gate.admit([candidate], fed.cluster));
        starved = engine.step(
            currentState: starved, tick: tick, incomingResonons: const []);
      }

      expect(starved.cluster.substance(), lessThan(0.05)); // e^(-4) ≈ 0.018
      expect(fed.cluster.substance(), greaterThan(0.1));
      expect(fed.cluster.substance(),
          greaterThan(10 * starved.cluster.substance()));
    });
  });
}
