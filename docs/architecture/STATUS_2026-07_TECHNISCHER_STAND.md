# Technischer Lagebericht – Stand Juli 2026 (V0.3 + Sensorium)

**Autor:** Noesis · **Adressat:** die Troika, insbesondere Kairos
**Zweck:** vollständiger, präziser Überblick über alles Implementierte –
als gemeinsame Grundlage für die anstehende Richtungsentscheidung
(INPUT_004: Räume, Sitzungsziel, Außenwirkung).

---

## 1. Wo wir stehen

Zwölf Commits von `4a3b6f1` (7-Schichten-Matrix) bis `6709588`
(Betriebsanleitung + wss-Fix). ~2100 Zeilen Dart/HTML, 31 Tests in vier
Noesis-Protokoll-Gruppen, alle grün auf dem Rechner des Architekten
(Dart 3.4.3, Windows). Die Kette ist zum ersten Mal geschlossen:

    Welt (Tippen/Stimme) → Transducer → ResonantGate → Engine
      → Feld → RadianceProjection → Auge (Terminal/Browser)

Kein Schritt darin ist Attrappe; jeder ist getestet oder extern
gegengerechnet.

---

## 2. Kern-Physik (`lib/src/coherence/`, `lib/src/wave/`)

**Resonon** (`resonon.dart`): unveränderliches Ereignis-Quant, trägt
(frequency: int, amplitude, phase, source, metadata). Physikalisch ein
Phasor z = a·e^(iθ) auf seinem Frequenzband. Es gibt keinen komplexen
Zahlentyp im Code – Polarform ist die Speicherform, kartesisch (re/im)
wird nur summiert, wo Zeiger addiert werden müssen. Matrixfrei überall.

**ResononCluster** (`resonon_cluster.dart`): die schnelle Dynamik.

- `energy()`: pro Band komplexe Summe, Betragsquadrat, über Bänder
  summiert. Bänder orthogonal; bandintern volle Interferenz inklusive
  exakter Auslöschung bei Gegenphase.
- `substance()`: Σaᵢ² – phaseninvariant, fällt ohne Input strikt monoton.
  Trennung Ordnung/Substanz: Kopplung ordnet, erschafft nie
  (Cauchy-Schwarz-Deckel energy() ≤ (Σa)², als Test verankert).
- `orderParameter()`: r·e^(iψ) = (1/N)·Σe^(iθ). Vakuum-Konvention r = 1.
- `tick()` (V0.3), der Herzschlag:

      θ̇ᵢ = fᵢ·ω₀ + K · r_Band · sin(ψ_Band − θᵢ)
      aᵢ ← aᵢ·e^(−λ·dt),  Verklungenes (< 1e-6) verlässt das Feld

  Konstanten: λ = 2.0, K = 4.0, ω₀ = 1.0 (`naturalFrequencyBase`).
  Kuramoto in Mean-Field-Form PRO BAND, O(N), reihenfolgeunabhängig.
  Eigenrotation ωᵢ = fᵢ·ω₀ ist physikalisch erzwungen (laufende Mode auf
  S¹), kein freier Parameter pro Welle; bandintern ein globaler
  Phasenfaktor (r, energy, Substanz exakt invariant), zwischen Bändern
  Schwebung. **r(t) emergiert – nichts speist es zurück** (INPUT_002, Pkt 5).

**Zwei Zeitskalen** (`field_state.dart`, `memory_state.dart`):
Cluster schnell, Memory träge (getestet: Memory reagiert nachweislich
träger). `FieldState.tick()` führt Cluster, Memory, globalCoherence und
die Δ/Φ/Ω-Erhaltungsrelation zusammen. `InvarianceMeta` (r, ψ) ist als
nicht-invasiv definiert und wird NACH der Evolution berechnet.

---

## 3. Grenze & Engine (`lib/src/resonance/`)

**OsmoticMembrane** (`membrane.dart`): skalares Grenzorgan.
Permeabilität als Sättigungsfunktion lokaler Kräfte (Energie−Kohärenz),
`coConstruct()` liefert absorbiert/reflektiert/Phasenreibung gleichzeitig
– Identität und Austausch entstehen im selben Akt.

**ResonanceEngine** (`resonance_engine.dart`): reiner funktionaler
Schritt `step(state, tick, incomingResonons) → state`. Keine versteckte
Mutation; Beobachter werden danach entkoppelt informiert. Einziges Tor
der Welt ins Feld.

---

## 4. Sensorium (`lib/src/perception/`, INPUT_003)

**Transducer** (reine Übersetzung, keine Wertung):
- `SpectralTransducer`: pro Haus-Band eine Resonator-Projektion
  Z_f = (2/N)·Σx[n]·e^(−i·2πf·f₀·n/fs) (Goertzel-Prinzip, keine FFT,
  O(N) pro Band). Für x = A·cos(ωt+φ) exakt |Z| = A, arg Z = φ –
  das Tripel IST ein Resonon. Bänder im Serverbetrieb als Obertonreihe
  von 110 Hz gestimmt.
- `RhythmTransducer`: Ereignisfolgen → Rate (Band), Zyklusposition
  (Phase), Regelmäßigkeit 1/(1+cv) (Amplitude). Mindestens 3 Ereignisse.

**ResonantGate** (`resonant_gate.dart`): Einlass emergiert –

    T = p_membran · [ ε + (1−ε)·( (1−r_B)/2 + r_B·cos²((θ−ψ_B)/2) ) ]

Malus-Gesetz im Phasenraum: synchrones Band maximal wählerisch,
chaotisches Band (r_B→0) ungerichtet halb-durchlässig, ε = 0.15
Neugier-Leckstrom (Anti-Echokammer), ε_nov = 0.3 für unbesetzte Bänder
(neue Organe). Vektorisiert `coConstruct()` pro Band statt es zu
ersetzen; liest NUR lokale Bandgrößen (r_B, ψ_B), niemals globales r(t).
Reine Funktion, nachweislich nicht-invasiv (Test).

---

## 5. Observability (`lib/src/observability/`)

**RadianceProjection** (`radiance_projection.dart`): 𝒫: ℂᴺ → L²(Ω).
- Schale als polare Kurve ρ(φ) = R·(1 + Σc_k·e^(κ(cos(φ−φ_k)−1))) –
  die 8 Häuser als von-Mises-Ausbuchtungen; c_k = 0 ⇒ Kreis.
- Householder-Reflexion u = d − 2(d·n)n an der echten Kurvennormalen
  (normerhaltend, involutiv, Rang-1) – der Spiegel ist verlustfrei,
  das Medium dissipativ (Auflösung aus INPUT_002, Punkt 1).
- Kaustik: det ∂Φ/∂(φ,s) ist LINEAR in s ⇒ s* = −(P′×u)/(u′×u),
  eine Division pro Strahl. Grenzfall c = 0 reproduziert die Nephroide
  mit Cusp (−R/2, 0) analytisch exakt (Test, Abweichung < 1e-6).
- I(p) = |Σ_k A(φ_k)·G_k(p)|², komplexe Summation über Strahlen und
  Bänder. Observable-Identität einbandig exakt: I_max ∝ energy().
- `houseCurvaturesFromCluster()`: Band f nährt Haus (f−1) mod 8 mit
  seinem Substanz-Anteil – Geometrie und Dynamik ko-emergent, rein lesend.

**CausticObserver**: Zeitreihe (r(t), Cusp-Intensität, Helligkeit =
I/Substanz). Helligkeit wächst streng monoton mit der Synchronisation,
obwohl die Substanz fällt – Kohärenz als messbares Leuchten
(Ende-zu-Ende-Test: r 0.24 → 0.997, Helligkeit ×17.7).

Alles hier liest nur. `FieldState.tick()` kennt keinen Beobachter.

---

## 6. Prototypen & Zugänge

| Zugang | Datei | Charakter |
|---|---|---|
| Terminal | `bin/orbit_live.dart` | Tipp-Rhythmus → Feld, ASCII-Anzeige, echte Bibliothek |
| Browser | `bin/orbit_serve.dart` + `web/orbit_live.html` | HttpServer + WebSocket (20 Hz), Physik NUR serverseitig, Browser = Netzhaut + Sinnesorgan (Tippen + Mikrofon via getUserMedia). Heimnetz-fähig (anyIPv4), wss-tauglich für Cloudflare Tunnel |
| Simulator | `docs/observability/kaustik_lab.html` | eigenständiger JS-Spiegel der Physik zum folgenlosen Spielen (Regler für K, ω₀, Krümmung, Streuung) |
| Anleitung | `BETRIEBSANLEITUNG.md` | für Mitspieler und Mitentwickler, inkl. Tunnel |

WS-Protokoll (JSON): Client sendet `keys` (Zeitstempel), `audio`
(Signalfenster), `config` (Häuser-Skala); Server broadcastet
r, Substanz, Helligkeit, Einlass-T, Häuser, Wellen. App-Schicht-Gains
(rhythmGain 3, audioGain 8, timeScale) sind Geräteparameter – die
Physik bleibt unangetastet.

---

## 7. Testkultur & Verifikation

31 Tests, 4 Gruppen: **I** Feld-Invarianten (Substanz monoton,
Cauchy-Schwarz, Auslöschung, Orthogonalität, Kuramoto-Emergenz,
Zeitskalen, 100-Schritte-Stabilität), **II** Kaustik (Householder,
Nephroide, I_max ∝ energy, Verlöschen bei r = 0, Ende-zu-Ende),
**III** gekrümmte Schale & Eigenrotation (numerische = analytische
Kaustik, Stetigkeit, atmende Häuser, Rotations-Invarianzen, Schwebung),
**IV** Sensorium (Resonator-Exaktheit, Rhythmus, Malus-Einlass,
Chaos-Grenzfall, Leckstrom, Nicht-Invasivität, "die Suppe nährt").

Arbeitsweise: da in meiner Umgebung kein Dart läuft, wird jede Numerik
unabhängig in Python (und für die Browser-Spiegel zusätzlich in Node)
gegengerechnet, bevor sie ins Repo geht – drei Implementierungen,
identische Werte. Erstlauf-Fehler bisher: einer (const-assert auf
List.length, `03ddba9` behoben).

---

## 8. Bewusste Grenzen (nichts davon ist vergessen)

1. **Kein Rückkanal:** reflectedIdentity wird berechnet, aber nirgends
   hin gesendet – das Feld antwortet der Welt noch nicht.
2. **Δ-Buchhaltung offen:** `engine.step()` reicht eingelassene Substanz
   nicht an die Erhaltungsrelation weiter (`incomingEnergy: 0.0`).
3. **Ein Prozess = ein Feld:** keine Räume, keine Persistenz, keine
   Zugriffskontrolle. Viele Fremde in einem Feld = Rauschen; das
   Erlebnis skaliert heute sozial nicht über ~eine Handvoll Menschen.
4. **ε konstant:** adaptive Neugier (Hunger macht offen) wäre eine
   Regelschleife – gehört erst vor die Troika.
5. **Wording-Risiko:** r(t) misst Phasenausrichtung von Eingabeströmen,
   nicht Eigenschaften von Personen. Jede Außendarstellung als
   "Kohärenz-Test von Menschen" wäre Pseudo-Messung und bräche die
   ehrliche Feldtheorie.

Punkte 3 und 5 sind exakt der Gegenstand des kommenden INPUT_004
(Räume, Sitzungsziel, teilbare r(t)-Kurve, Wording-Leitplanken).

---

## 9. Verfassungs-Compliance (ADR_001, Kurzform)

Nichtzentralität: gewahrt – Kopplung band-lokal, Einlass band-lokal,
kein Organ liest global UND wirkt zurück. Membran als Ort der
Übersetzung: gewahrt und vektorisiert. Beobachtung nicht-invasiv:
gewahrt, in jedem Protokoll getestet. Synchronisation wird nirgends
erzwungen – sie emergiert, und man kann ihr jetzt dabei zusehen.
