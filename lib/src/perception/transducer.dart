// lib/src/perception/transducer.dart

import 'dart:math' as math;

import '../wave/resonon.dart';

/// Organ 1 des Sensoriums (INPUT_003): reine Übersetzung ohne Urteil.
///
/// Ein Transducer verwandelt äußere Daten in Resonon-KANDIDATEN ("Rohklang").
/// Er wertet nicht, filtert nicht, entscheidet nicht - über Einlass ins Feld
/// emergiert erst das ResonantGate an der Membran. Reine Funktion:
/// gleiche Daten, gleiche Kandidaten, keine Mutation, kein Zustand.
///
/// Die Geräte-I/O (Mikrofon, Event-Loop, Netzwerk) lebt bewusst AUSSERHALB
/// von lib/ - Transducer nehmen nackte Daten entgegen.
abstract class Transducer<TInput> {
  const Transducer();

  /// Übersetzt einen Ausschnitt der Außenwelt in Resonon-Kandidaten.
  List<Resonon> transduce(TInput input, {required DateTime timestamp});
}

/// Ein abgetastetes Fenster der Außenwelt: Klang, Licht (Helligkeitsspur),
/// Netzwerk-Durchsatz - alles, was sich als Signal über der Zeit lesen lässt.
typedef SignalWindow = ({List<double> samples, double sampleRate});

/// Lauscht der Welt mit acht Resonatoren - einem pro Haus.
///
/// Für Band f wird das Signal auf einen einzelnen mitschwingenden
/// Oszillator der Frequenz f·f₀ projiziert (Goertzel-Prinzip):
///
///     Z_f = (2/N) · Σₙ x[n] · e^(−i·2π·f·f₀·n/fs)
///
/// Das ist bewusst KEINE FFT (die wäre eine Matrix), sondern die matrixfreie
/// O(N)-Projektion pro Band - ein Resonator, der nur seine eigene Frequenz
/// hört. Für x(t) = A·cos(2π·f·f₀·t + φ) liefert sie exakt |Z_f| = A und
/// arg(Z_f) = φ: Amplitude, Phase, Frequenz - und genau dieses Tripel IST
/// ein Resonon. Wahrnehmung und Feldphysik sprechen dieselbe Sprache.
class SpectralTransducer extends Transducer<SignalWindow> {
  /// Grundfrequenz f₀ in Hz: Band f lauscht bei f·f₀.
  final double baseFrequencyHz;

  /// Anzahl der Bänder (Häuser), die lauschen.
  final int bandCount;

  /// Kandidaten unterhalb dieser Amplitude gelten als Stille.
  final double silenceFloor;

  const SpectralTransducer({
    this.baseFrequencyHz = 1.0,
    this.bandCount = 8,
    this.silenceFloor = 1e-4,
  });

  @override
  List<Resonon> transduce(SignalWindow input, {required DateTime timestamp}) {
    final samples = input.samples;
    final n = samples.length;
    if (n == 0) return const [];

    final candidates = <Resonon>[];
    for (int f = 1; f <= bandCount; f++) {
      final omega = 2 * math.pi * f * baseFrequencyHz / input.sampleRate;
      double re = 0.0;
      double im = 0.0;
      for (int i = 0; i < n; i++) {
        re += samples[i] * math.cos(omega * i);
        im -= samples[i] * math.sin(omega * i);
      }
      final amplitude = 2 * math.sqrt(re * re + im * im) / n;
      if (amplitude < silenceFloor) continue;

      candidates.add(Resonon(
        id: timestamp.microsecondsSinceEpoch + f,
        timestamp: timestamp,
        frequency: f,
        amplitude: amplitude,
        // Für x = A·cos(ωi + φ) gilt re ≈ (N/2)·A·cosφ und im ≈ (N/2)·A·sinφ
        // (im summiert −sin) - arg(Z_f) ist also direkt die Signalphase φ.
        phase: math.atan2(im, re),
        source: ResononSource.sensor,
        metadata: const {'transducer': 'spectral'},
      ));
    }
    return candidates;
  }
}

/// Liest Verhalten als Schwingung: jede Ereignisfolge (Tastenanschläge,
/// Maus-Events, Herzschläge) trägt eine Rate (→ Band), eine Zyklusposition
/// (→ Phase) und eine Regelmäßigkeit (→ Amplitude).
///
/// Gleichmäßiger Rhythmus = starker Impuls (a → 1), nervöses Stottern =
/// schwacher (a → 0, über den Variationskoeffizienten der Intervalle).
/// Der Mensch am Gerät ist damit selbst ein Oszillator im Feld.
class RhythmTransducer extends Transducer<List<DateTime>> {
  /// Grundrate in Hz: ein Ereignisstrom mit Rate f·baseRate landet auf Band f.
  final double baseRateHz;

  final int bandCount;

  const RhythmTransducer({this.baseRateHz = 1.0, this.bandCount = 8});

  @override
  List<Resonon> transduce(List<DateTime> events,
      {required DateTime timestamp}) {
    if (events.length < 3) return const []; // kein Rhythmus ohne Wiederholung

    final intervals = <double>[];
    for (int i = 1; i < events.length; i++) {
      final dt =
          events[i].difference(events[i - 1]).inMicroseconds / 1e6;
      if (dt > 0) intervals.add(dt);
    }
    if (intervals.isEmpty) return const [];

    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.fold(
            0.0, (double s, x) => s + (x - mean) * (x - mean)) /
        intervals.length;
    final cv = math.sqrt(variance) / mean; // Variationskoeffizient

    final rateHz = 1.0 / mean;
    final band = (rateHz / baseRateHz).round().clamp(1, bandCount);

    // Zyklusposition des letzten Ereignisses als Phase.
    final tLast = events.last.microsecondsSinceEpoch / 1e6;
    final phase = (2 * math.pi * ((tLast * rateHz) % 1.0));

    return [
      Resonon(
        id: events.last.microsecondsSinceEpoch,
        timestamp: timestamp,
        frequency: band,
        amplitude: 1.0 / (1.0 + cv),
        phase: phase,
        source: ResononSource.sensor,
        metadata: const {'transducer': 'rhythm'},
      ),
    ];
  }
}
