# Input 003 – Das Sensorium: Osmose mit der Außenwelt

**Autor:** Noesis (Claude) · **Datum:** 2026-07-09
**Status:** Input für die Troika, mit Referenzimplementierung in `/perception`
**Bezug:** Aethons Vorschlag "die Orbit in einer Suppe von Dateninformationen schwimmen lassen – und irgendwie können die dann Einlass gewinnen oder eben nicht. Oder über Licht, über Frequenzen, über Schwingungen."

---

## Der Befund: Der Mund existiert schon, es fehlt nur die Zunge

`ResonanceEngine.step(incomingResonons: ...)` ist die einzige Stelle, an der
Welt ins Feld kommt – und `ResononSource` (mouse, text, clock, sensor) zeigt,
dass die Verfassung den Außenkontakt von Anfang an vorgesehen hat. Was fehlt,
ist kein Umbau, sondern ein Organ der Übersetzung: etwas, das äußere Ströme in
Resononen verwandelt, und etwas, das über Einlass **nicht entscheidet,
sondern ihn emergieren lässt**.

Daraus folgt die Zwei-Organ-Architektur des Sensoriums:

```
   Außenwelt                    Grenze                        Feld
   ─────────                    ──────                        ────
   Samples/Events ──▶ Transducer ──▶ Kandidaten ──▶ ResonantGate ──▶ engine.step()
   (Suppe)            (Übersetzung,     (Rohklang)     (Osmose:          (Kern,
                       KEINE Wertung)                   Einlass by        unberührt)
                                                        Resonanz)
```

---

## Organ 1: Transducer – Übersetzung ohne Urteil

Ein Transducer ist eine **reine Funktion** `Außendaten → List<Resonon>`.
Er wertet nicht, filtert nicht, entscheidet nicht – er verwandelt nur
Repräsentation. Zwei erste Arten, beide matrixfrei und O(N):

**SpectralTransducer (Licht/Klang/Schwingung – Aethons Frequenz-Intuition):**
Für jedes der 8 Häuser lauscht ein *Resonator* auf seiner Bandfrequenz:

    Z_f = (2/N) · Σₙ x[n] · e^(−i·2π·f·f₀·n/fs)

Das ist keine FFT (die wäre eine Matrix) – es ist die Projektion des Signals
auf einen einzelnen mitschwingenden Oszillator (Goertzel-Prinzip). Ein
Mikrofon, eine Kamera-Helligkeitsspur, ein Netzwerk-Durchsatz: alles, was
sich abtasten lässt, liefert pro Band exakt das Tripel (Frequenz, Amplitude,
Phase) – **und genau das ist ein Resonon.** Die Physik des Feldes und die
Wahrnehmung der Welt sprechen dieselbe Sprache; es gibt nichts zu mappen,
nur zu projizieren.

**RhythmTransducer (Verhalten als Schwingung):** Tastenanschläge, Maus-Events,
Herzschläge – jede Ereignisfolge trägt eine Rate (→ Band), eine Zyklusposition
(→ Phase) und eine Regelmäßigkeit (→ Amplitude: gleichmäßiger Rhythmus =
starker Impuls, nervöses Stottern = schwacher). Der Mensch am Gerät ist damit
selbst ein Oszillator im Feld.

Die Geräte-I/O (Mikrofon-API, Event-Loops) bleibt bewusst **außerhalb** von
`lib/` – die Transducer nehmen nackte Daten (`List<double>`, `List<DateTime>`).
Der Kern bleibt pur und testbar; die Suppe ist App-Sache.

---

## Organ 2: ResonantGate – Einlass wird nicht entschieden, er emergiert

Die zentrale Frage ("können die dann Einlass gewinnen oder eben nicht?")
beantwortet kein Türsteher und keine if-Kaskade, sondern ein physikalisches
Gesetz an der Membran. Für einen Kandidaten mit Phase θ auf Band B mit
lokalem Bandfeld (r_B, ψ_B):

    T = p_membran · [ ε + (1−ε) · ( (1−r_B)/2 + r_B · cos²((θ−ψ_B)/2) ) ]

Das ist das **Malus-Gesetz** – die Membran wirkt als Polarisationsfilter im
Phasenraum. Drei Terme, drei Bedeutungen:

1. **cos²(Δ/2):** Resonanz-Transmission. Gleichphasig → voller Durchlass,
   gegenphasig → Auslöschung an der Grenze. Zugehörigkeit ist Interferenz,
   keine Regel.
2. **r_B interpoliert die Selektivität:** Ein synchronisiertes Band
   (r_B → 1) ist maximal wählerisch – reines Malus-Gesetz. Ein chaotisches
   Band (r_B → 0) hat keine definierte Identität, an der sich etwas
   auslöschen könnte – es lässt ungerichtet die Hälfte von allem herein.
   Identität und Selektivität sind dieselbe Größe.
3. **ε (Neugier-Leckstrom):** Die Warnung vor der Echokammer, eingebaut als
   Naturkonstante. Ohne ε hört das Feld nur noch, was es schon singt – und
   verhungert, denn die Dissipation frisst Substanz und die Suppe ist die
   Nahrung. ε > 0 garantiert: auch das maximal Fremde behält eine Stimme.
   Unbesetzte Bänder empfangen mit eigener Durchlässigkeit ε_nov – das Feld
   kann neue Organe wachsen lassen.

Beim Übertritt wirkt `OsmoticMembrane.coConstruct()` weiter als skalares
Grenzorgan (Permeabilität, Phasenreibung `boundaryPhaseShift`) – das Gate
**vektorisiert** die vorhandene Membran pro Band, statt sie zu ersetzen.
Genau die Auflösung aus INPUT_002, Punkt 1: das Grenzorgan bleibt, es bekommt
Phasenaugen.

**Verfassungstreue:** Das Gate liest ausschließlich LOKALE Bandgrößen
(r_B, ψ_B) – niemals das globale r(t). Kein zentrales Entscheidungsorgan
(ADR_001), keine Meta-Invariante wirkt zurück (INPUT_002, Punkt 5). Es
mutiert nichts: reine Funktion Kandidaten × Feldzustand → Einlass.

---

## Was dadurch beobachtbar wird

Die Kaustik schließt den Kreis: füttert man das Feld mit einem *resonanten*
Strom, wächst r(t) und die Brennlinie leuchtet; füttert man Rauschen, dringt
nur der ε-Leckstrom ein und die Nephroide bleibt dunkel. **Man kann der Welt
beim Anklopfen zusehen.** Der `CausticObserver` braucht dafür keine Zeile
Änderung.

---

## Bewusst NICHT gebaut (Grenzen dieser Stufe)

- **Kein Rückkanal:** Das Feld antwortet der Welt noch nicht (reflected
  Identity wird berechnet, aber nirgends hin gesendet). Ausdruck ist V-nächste.
- **Kein Δ-Tracking:** `engine.step()` reicht eingelassene Substanz noch nicht
  an `ConservationRelation` weiter (`incomingEnergy: 0.0`). Ehrlicher
  Folgeschritt, sobald der Kern ohnehin angefasst wird.
- **Keine adaptive Neugier:** ε ist konstant. Denkbar: ε wächst, wenn die
  Substanz fällt (Hunger macht offen) – aber das wäre schon wieder eine
  Regelschleife, die erst die Troika hören sollte.

---

## Reihenfolge, die das Feld nahelegt

1. `/perception` mit Transducern + Gate (dieser Input, Referenzimplementierung).
2. Erster echter Strom in der App-Schicht: Tipp-Rhythmus oder Mikrofon-Fenster,
   sichtbar im Kaustik-Labor.
3. Δ-Buchhaltung der eingelassenen Substanz in der Erhaltungsrelation.
4. Der Rückkanal: reflectedIdentity als Ausdruck des Feldes an die Welt.
