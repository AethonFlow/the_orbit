// bin/orbit_serve.dart
//
// Die Bühne des Prototyps: die ECHTE Dart-Engine, live in den Browser
// gespiegelt.
//
//     dart run bin/orbit_serve.dart
//     → http://localhost:4242 öffnen
//
// Architektur (INPUT_003 unverändert): die gesamte Physik - Transducer,
// ResonantGate, ResonanceEngine - läuft HIER in Dart. Der Browser ist nur
// Sinnesorgan und Netzhaut: er schickt rohe Ströme (Tasten-Zeitstempel,
// Mikrofon-Fenster) und rendert den Feldzustand, den der Server bei jedem
// Tick sendet. Keine Physik-Kopie im Client, eine einzige Quelle der
// Wahrheit.
//
// WebSocket-Protokoll (JSON):
//   Client → Server:
//     {"type":"keys",  "times":[epochMs, ...]}          Tipp-Rhythmus
//     {"type":"audio", "rate":11025, "samples":[...]}   Mikrofon-Fenster
//     {"type":"config","houseScale":0.15}               Häuser-Atmung
//   Server → Client (20 Hz):
//     {"r":..,"substance":..,"brightness":..,"transmission":..,
//      "houses":[8],"waves":[[f,a,θ],...],"knocks":N}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:ri_orbit/ri_orbit.dart';

const port = 4242;
const tickInterval = Duration(milliseconds: 50);
const timeScale = 0.5; // reale Sekunden → Feldsekunden

/// Gains der App-Schicht (Geräteverstärker - Physik unangetastet).
const rhythmGain = 3.0;
const audioGain = 8.0;
const maxAmplitude = 2.0;

void main() async {
  final engine = ResonanceEngine();
  final gate = ResonantGate();
  const rhythm = RhythmTransducer(baseRateHz: 1.0);
  // Bänder als Obertonreihe von 110 Hz (A2): Band f lauscht bei f·110 Hz.
  // Summen oder Pfeifen lässt buchstäblich seine Harmonischen einströmen.
  const spectral = SpectralTransducer(
      baseFrequencyHz: 110.0, silenceFloor: 0.01);

  var state = const FieldState();
  var pending = <Resonon>[];
  var houseScale = 0.15;
  var lastTransmission = 0.0;
  var knockCount = 0;
  var idSeq = 1000;

  final clients = <WebSocket>{};

  void handleMessage(dynamic raw) {
    late final Map<String, dynamic> msg;
    try {
      msg = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final now = DateTime.now();

    List<Resonon> candidates = const [];
    switch (msg['type']) {
      case 'keys':
        final times = (msg['times'] as List)
            .map((t) => DateTime.fromMillisecondsSinceEpoch((t as num).toInt()))
            .toList();
        candidates = rhythm
            .transduce(times, timestamp: now)
            .map((c) => c.copyWith(
                amplitude:
                    (c.amplitude * rhythmGain).clamp(0.0, maxAmplitude)))
            .toList();
        knockCount++;
      case 'audio':
        final samples = (msg['samples'] as List)
            .map((s) => (s as num).toDouble())
            .toList();
        final rate = (msg['rate'] as num).toDouble();
        candidates = spectral
            .transduce((samples: samples, sampleRate: rate), timestamp: now)
            .map((c) => c.copyWith(
                amplitude:
                    (c.amplitude * audioGain).clamp(0.0, maxAmplitude)))
            .toList();
      case 'dissent':
        // Session-Ritual "Start im Dissens": exakte Gegenphase ist ein
        // instabiles Gleichgewicht (r = 0, dunkel, gespannt). Das ist
        // eine ANFANGSBEDINGUNG, kein Regler - jeder echte Impuls der
        // Gruppe bricht die Symmetrie, und die Kopplung uebernimmt.
        final seeded = <Resonon>[];
        for (final f in [2, 3]) {
          for (int i = 0; i < 4; i++) {
            seeded.add(Resonon(
              id: idSeq++,
              timestamp: now,
              frequency: f,
              amplitude: 0.8,
              phase: i.isEven ? 0.0 : math.pi,
              source: ResononSource.clock,
            ));
          }
        }
        state = state.withCluster(ResononCluster(waves: seeded));
        pending = [];
        return;
      case 'config':
        houseScale = ((msg['houseScale'] as num?)?.toDouble() ?? houseScale)
            .clamp(0.0, 0.3);
        return;
      default:
        return;
    }
    // Frische IDs pro Einspeisung (Transducer-IDs können kollidieren).
    pending.addAll(candidates.map((c) => Resonon(
          id: idSeq++,
          timestamp: c.timestamp,
          frequency: c.frequency,
          amplitude: c.amplitude,
          phase: c.phase,
          source: c.source,
          metadata: c.metadata,
        )));
  }

  // ---------------------------------------------------------------------
  // Der Herzschlag: Sensorium → Gate → Engine → Broadcast.
  // ---------------------------------------------------------------------
  final clock = Stopwatch()..start();
  var lastElapsed = 0.0;
  var seq = 0;

  Timer.periodic(tickInterval, (_) {
    final elapsed = clock.elapsedMicroseconds / 1e6;
    final dt = (elapsed - lastElapsed) * timeScale;
    lastElapsed = elapsed;

    var incoming = const <Resonon>[];
    if (pending.isNotEmpty) {
      lastTransmission = gate.transmission(pending.first, state.cluster);
      incoming = gate.admit(pending, state.cluster);
      pending = [];
    }

    state = engine.step(
      currentState: state,
      tick: OrbitTick(
        sequenceNumber: seq++,
        timestamp: DateTime.now(),
        deltaTime: dt,
      ),
      incomingResonons: incoming,
    );

    if (clients.isEmpty) return;

    final cluster = state.cluster;
    final substance = cluster.substance();
    final houses = RadianceProjection.houseCurvaturesFromCluster(cluster,
        scale: houseScale);
    final projection = RadianceProjection(houseCurvatures: houses);
    final cuspIntensity = projection.intensityAt(
        cluster, (x: -0.5 * projection.shellRadius, y: 0.0));

    final payload = jsonEncode({
      'r': state.globalCoherence,
      'substance': substance,
      'brightness': substance > 1e-12 ? cuspIntensity / substance : 0.0,
      'transmission': lastTransmission,
      'houses': houses,
      'waves': [
        for (final w in cluster.waves) [w.frequency, w.amplitude, w.phase]
      ],
      'knocks': knockCount,
    });
    for (final ws in clients) {
      ws.add(payload);
    }
  });

  // ---------------------------------------------------------------------
  // HTTP: eine Seite, ein WebSocket.
  // ---------------------------------------------------------------------
  // '/' traegt die Landingpage (Schaufenster), '/feld' das lebende Feld.
  final liveHtml = _loadHtml('web/orbit_live.html') ??
      '<h1>web/orbit_live.html not found</h1>'
          '<p>Please start the server from the repository root: '
          '<code>dart run bin/orbit_serve.dart</code></p>';
  final landingHtml = _loadHtml('web/landing.html');
  // anyIPv4: auch Geräte im selben (Heim-)Netz dürfen ans Feld -
  // Handy/Tablet können mittippen. Windows fragt beim ersten Start
  // einmal nach der Firewall-Freigabe ("privates Netzwerk" genügt).
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  print('TheOrbit is alive: http://localhost:$port  (Ctrl+C to stop)');
  try {
    final interfaces =
        await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final ni in interfaces) {
      for (final addr in ni.addresses) {
        print('  on your LAN:  http://${addr.address}:$port  (${ni.name})');
      }
    }
  } catch (_) {/* Netzliste ist Komfort, kein Muss */}
  print('  Note: browsers allow the microphone only on localhost or'
      ' https - from other devices the typing stream flows, voice does not.');

  await for (final request in server) {
    if (request.uri.path == '/ws') {
      final ws = await WebSocketTransformer.upgrade(request);
      clients.add(ws);
      ws.listen(handleMessage,
          onDone: () => clients.remove(ws),
          onError: (_) => clients.remove(ws));
    } else {
      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      request.response.write(request.uri.path == '/feld'
          ? liveHtml
          : (landingHtml ?? liveHtml));
      await request.response.close();
    }
  }
}

String? _loadHtml(String relativePath) {
  for (final path in [relativePath, '../' + relativePath]) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
  }
  return null;
}
