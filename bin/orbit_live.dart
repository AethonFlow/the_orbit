// bin/orbit_live.dart
//
// Der erste lebende Prototyp (INPUT_003, Schritt 2): TheOrbit schwimmt in
// einem echten Strom - deinem Tipp-Rhythmus.
//
//     dart run bin/orbit_live.dart
//
// Jeder Tastendruck ist ein Klopfen an der Membran: die Zeitstempel fließen
// durch den RhythmTransducer (Rate → Band, Regelmäßigkeit → Amplitude),
// das ResonantGate lässt sie nach dem Malus-Gesetz ein oder nicht, und die
// Engine atmet in Echtzeit. Beobachtet wird nicht-invasiv: r(t), die
// Helligkeit der Nephroiden-Kaustik am Cusp und die Pegel der acht Häuser.
//
// Dein Tempo wählt das Haus: ~1 Anschlag/s → Band 1, ~4/s → Band 4.
// Gleichmäßig tippen = starker Impuls; stottern = schwacher.
// 'q' beendet.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:ri_orbit/ri_orbit.dart';

/// Verstärkung des Eingangsstroms (App-Schicht, wie ein Mikrofon-Gain -
/// die Physik von Gate und Feld bleibt unangetastet).
const inputGain = 3.0;

/// Zeitlupe: reale Sekunden → Feldsekunden. Lässt das Feld langsam genug
/// atmen, um dem Zerfall zuzusehen.
const timeScale = 0.35;

const tickInterval = Duration(milliseconds: 50);
const maxEvents = 8; // Gleitfenster des Rhythmus

void main() async {
  final engine = ResonanceEngine();
  final observer = CausticObserver();
  engine.registerObserver(observer);

  final gate = ResonantGate();
  const transducer = RhythmTransducer(baseRateHz: 1.0);

  var state = const FieldState();
  final keyTimes = <DateTime>[];
  var pendingKnock = false;
  var knockCount = 0;
  var lastTransmission = 0.0;
  final rHistory = <double>[];

  // Terminal in den Rohmodus: jede Taste sofort, ohne Echo.
  // (Unter Windows am besten im Windows Terminal starten - UTF-8.)
  bool hadEcho = true;
  bool hadLine = true;
  try {
    hadEcho = stdin.echoMode;
    hadLine = stdin.lineMode;
    stdin.echoMode = false;
    stdin.lineMode = false;
  } on StdinException {
    stderr.writeln('Kein interaktives Terminal - bitte direkt in einer '
        'Konsole starten.');
    exit(1);
  }

  void restoreTerminal() {
    stdin.echoMode = hadEcho;
    stdin.lineMode = hadLine;
    stdout.write('\x1B[?25h'); // Cursor wieder zeigen
  }

  StreamSubscription<List<int>>? keys;
  Timer? loop;

  void shutdown() {
    loop?.cancel();
    keys?.cancel();
    restoreTerminal();
    stdout.writeln('\nDas Feld verklingt. (${knockCount}x geklopft)');
    exit(0);
  }

  keys = stdin.listen((bytes) {
    for (final b in bytes) {
      if (b == 0x71 /* q */ || b == 0x03 /* Ctrl-C */) shutdown();
      keyTimes.add(DateTime.now());
      if (keyTimes.length > maxEvents) keyTimes.removeAt(0);
      pendingKnock = true;
      knockCount++;
    }
  });

  stdout.write('\x1B[2J\x1B[H\x1B[?25l'); // Bildschirm frei, Cursor aus

  final clock = Stopwatch()..start();
  var lastElapsed = 0.0;
  var seq = 0;

  loop = Timer.periodic(tickInterval, (_) {
    final elapsed = clock.elapsedMicroseconds / 1e6;
    final dt = (elapsed - lastElapsed) * timeScale;
    lastElapsed = elapsed;

    final tick = OrbitTick(
      sequenceNumber: seq++,
      timestamp: DateTime.now(),
      deltaTime: dt,
    );

    // Die Welt klopft: nur wenn seit dem letzten Tick eine Taste kam.
    var incoming = const <Resonon>[];
    if (pendingKnock && keyTimes.length >= 3) {
      pendingKnock = false;
      final candidates = transducer
          .transduce(List.of(keyTimes), timestamp: tick.timestamp)
          .map((c) => c.copyWith(amplitude: c.amplitude * inputGain))
          .toList();
      if (candidates.isNotEmpty) {
        lastTransmission = gate.transmission(candidates.first, state.cluster);
        incoming = gate.admit(candidates, state.cluster);
      }
    } else {
      pendingKnock = false;
    }

    state = engine.step(
      currentState: state,
      tick: tick,
      incomingResonons: incoming,
    );

    final r = state.globalCoherence;
    rHistory.add(r);
    if (rHistory.length > 48) rHistory.removeAt(0);

    if (seq % 2 == 0) {
      render(state, observer, rHistory, lastTransmission, knockCount);
    }
  });
}

// ---------------------------------------------------------------------------
// Rendering (reiner Beobachter)
// ---------------------------------------------------------------------------

String bar(double value, {int width = 28}) {
  final v = value.clamp(0.0, 1.0);
  final full = (v * width).floor();
  final rest = (v * width) - full;
  const blocks = ' ▏▎▍▌▋▊▉█';
  final partial = full < width ? blocks[(rest * 8).round()] : '';
  return ('█' * full) + partial + (' ' * (width - full - partial.length));
}

String sparkline(List<double> values) {
  const glyphs = '▁▂▃▄▅▆▇█';
  return values
      .map((v) => glyphs[(v.clamp(0.0, 1.0) * 7).round()])
      .join();
}

void render(
  FieldState state,
  CausticObserver observer,
  List<double> rHistory,
  double lastTransmission,
  int knockCount,
) {
  final cluster = state.cluster;
  final r = state.globalCoherence;
  final substance = cluster.substance();

  final brightness =
      observer.samples.isEmpty ? 0.0 : observer.samples.last.brightness;
  // Sichtbarkeits-Skala fürs Terminal (Helligkeit wächst schnell).
  final brightNorm = math.log(1 + brightness) / math.log(1 + 200);

  // Pegel der acht Häuser: √(Band-Substanz), gedeckelt.
  final bandLevel = List<double>.filled(8, 0.0);
  for (final w in cluster.waves) {
    final h = (w.frequency - 1) % 8;
    bandLevel[h] += w.amplitude * w.amplitude;
  }

  final b = StringBuffer('\x1B[H');
  b.writeln('╔══════════════════════════════════════════════════════════╗');
  b.writeln('║  TheOrbit · lebender Prototyp — tippe, das Feld hört zu  ║');
  b.writeln('╚══════════════════════════════════════════════════════════╝');
  b.writeln();
  b.writeln('  r(t) Kohärenz   │${bar(r)}│ ${r.toStringAsFixed(3)}');
  b.writeln('  Kaustik am Cusp │${bar(brightNorm)}│ '
      '${brightness.toStringAsFixed(1)}');
  b.writeln('  Substanz Σa²    │${bar(math.min(1.0, substance))}│ '
      '${substance.toStringAsFixed(3)}');
  b.writeln();
  b.writeln('  r(t) Verlauf    ${sparkline(rHistory)}');
  b.writeln();
  b.writeln('  Die 8 Häuser (Band-Substanz):');
  for (int h = 0; h < 8; h++) {
    final level = math.min(1.0, math.sqrt(bandLevel[h]));
    b.writeln('    Haus ${h + 1} (f=${h + 1}) │${bar(level, width: 20)}│');
  }
  b.writeln();
  b.writeln('  letzter Einlass T = ${(lastTransmission * 100).round()}%'
      '   ·   ${knockCount}x geklopft   ·   '
      '${cluster.activeWavesCount} Wellen aktiv');
  b.writeln();
  b.writeln('  Dein Tempo wählt das Haus (≈1/s → Haus 1, ≈4/s → Haus 4).');
  b.writeln('  Gleichmäßig = kräftiger Einlass. q = beenden.  \x1B[0J');
  stdout.write(b);
}
