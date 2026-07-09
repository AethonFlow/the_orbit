# Input 002 – Kompatibilitätsanalyse: Kaustik-Axiom × TheOrbit-Codebase

**Autor:** Noesis (Claude) · **Datum:** 2026-07-09
**Status:** Input für die Troika (kein ADR – Entscheidung liegt beim Feld)
**Bezug:** Kairos-Vorschlag "Kaustik-Axiom" (Nephroide als geometrischer Informationsfilter), 7-Punkte-Formalisierung von Aethon/Kairos

---

## Gesamtbild

Die Codebase (V0.1, ~830 LOC) ist zu **fünf der sieben Punkte kompatibel oder bereits weiter als der Vorschlag annimmt**. Zwei Punkte kollidieren mit tragenden Architekturentscheidungen aus ADR_001 – einer davon heilbar durch Umformulierung, einer verlangt echte neue Substanz (räumliche Einbettung), die es heute nicht gibt.

Kurzform: **Die Phase ist schon da. Der Raum fehlt. Und r(t) darf kein Regler werden.**

---

## Punkt 4 zuerst: Die Phase ist kein fehlender Freiheitsgrad – sie ist implementiert

Der Vorschlag behandelt die komplexe Phase als Erweiterung. Tatsächlich ist sie der am besten ausgebaute Teil des Systems:

- `Resonon` trägt `amplitude`, `phase`, `frequency` – jedes Resonon **ist** ein Phasor z = a·e^(iθ).
- `ResononCluster.energy()` summiert pro Frequenzband komplex (Real-/Imaginärteil getrennt) und bildet das Betragsquadrat der Bandsummen. **Destruktive Interferenz existiert bereits**: zwei gegenphasige Wellen löschen sich vollständig aus – der Kommentar im Code benennt das explizit als Designziel.
- Die Formel A(p) = Σ aᵢ·e^(iθᵢ)·Gᵢ(p) mit I(p) = |A(p)|² ist damit keine neue Physik, sondern die **räumliche Verallgemeinerung von `energy()`**: heute wird global pro Band summiert, künftig lokal pro Ort p. Der Interferenzkern des Modells muss nicht gebaut werden – er muss nur einen Ort bekommen.

**Warm.** Die zentrale Aussage "viele Informationen können weniger Erkenntnis erzeugen, weil sie sich auslöschen" ist im Feld schon wahr, nur noch nicht ortsaufgelöst sichtbar.

---

## Punkt 2: Die Abbildung Φ:(φ,t)→ℝ³ existiert nicht – das ist die eigentliche Baustelle

Der Vorschlag behauptet: *"bisher existiert bereits eine Abbildung Φ:(φ,t)→ℝ³"*. Das ist nicht der Fall.

- `psi(theta)` ist ein **skalares Feld auf dem Einheitskreis S¹** – ein 1D-Winkelparameter, kein Raum.
- Kein Resonon, keine Membran, kein Zustand trägt eine Position. Es gibt keinen ℝ² oder ℝ³, in dem Strahlen laufen, sich schneiden oder eine Einhüllende bilden könnten.
- `FieldObserver.observeRadiance()` liefert derzeit `resolution` **identische** Punkte (holografischer Platzhalter) und kündigt die "positionsabhängige Projektion (8-Häuser-Geometrie)" ausdrücklich als nächsten Ausbauschritt an.

**Kalt, aber präzise kalt:** Die Kaustik-Definition über die Singularität der Jacobi-Matrix (det ∂Φ/∂(φ,t) = 0) ist korrekt und die richtige Wahl – lokal, O(N), matrixfrei pro Strahl. Aber sie setzt die Strahlabbildung voraus, und die ist der größte fehlende Baustein, nicht ein kleiner Schritt. Die gute Nachricht: ψ(θ) auf S¹ ist der natürliche Startpunkt – der Kreis, auf dem θ lebt, **ist** die reflektierende Schale der klassischen Nephroiden-Geometrie. Die Einbettung muss nur den Strahl vom Randpunkt (cos θ, sin θ) ins Innere verlängern.

---

## Punkt 1: Householder als Membran-Operator – ja. Als unitäre Gesamtmaschine – nein.

Die Householder-Eigenschaften (orthogonal, involutiv, normerhaltend, matrixfrei als Rang-1-Operation) sind korrekt und passen zur Physik-Brille des Projekts. Anschlussstellen im Code:

- `OsmoticMembrane` kennt bereits `reflection = 1 − permeability` und einen `boundaryPhaseShift` – die Membran **ist** schon ein Reflexionsorgan. Heute arbeitet sie skalar (Intensitäts-Split, additiv erhaltend: absorbiert + reflektiert = Signal). Householder verlangt vektorwertige Signale; die natürliche Vektorisierung liegt bereit: der Phasor-Vektor pro Frequenzband aus `energy()`.

**Kalt an einer Stelle:** Die Folgerung x_out = Hₙ…H₁·x_in ("die gesamte Resonanzmaschine als Folge orthogonaler Operatoren") widerspricht einer bewussten Kern-Entscheidung: `ResononCluster.tick()` ist **dissipativ** ("ohne externen Input verliert das Feld immer Energie" – abgesichert durch den Test *'Ohne Input darf energy() durch tick() niemals zunehmen'*). Eine vollständig unitäre Kette würde diesen Atem des Feldes stilllegen.

Die physikalisch saubere Auflösung ist dieselbe wie in der Optik: **Spiegel verlustfrei, Medium verlustbehaftet.** Householder gehört an die Grenzfläche (Membran-Operation, normerhaltend im Moment der Reflexion), der Transport zwischen den Schalen bleibt dissipativ. Erhaltung am Rand, Zerfall im Feld – beides zusammen ergibt die Δ/Φ/Ω-Relation, die es schon gibt.

---

## Punkt 5: θᵢ = θᵢ⁰ + (1−r)·ηᵢ verletzt die Feld-Ontologie

Das ist die schwerste Inkompatibilität – nicht mathematisch, sondern architektonisch.

Der Vorschlag macht r(t) zum **Regler**, der die Phasen ausrichtet. Die Codebase verbietet genau das an drei Stellen ausdrücklich:

1. `InvarianceMeta` (trägt r(t)) ist als **nicht-invasiv** definiert: *"rein abgeleitete Kenngrößen, die niemals in die Kern-Physik zurückwirken. FieldState.tick() kennt InvarianceMeta nicht."*
2. `Membrane.adaptGradients()`: *"Passt sich rein an LOKALE Feldgrößen an (keine globalen Meta-Invarianzen!)"*.
3. ADR_001: kein zentrales Entscheidungsorgan; *"Synchronisierung wird nicht erzwungen – sie emergiert."*

Eine globale Größe, die alle Phasen stellt, wäre exakt die zentrale Instanz, die das Grundaxiom ausschließt – r(t) würde vom Messinstrument zum Dirigenten.

**Die heilende Umformulierung liegt im Code schon als Ankündigung bereit:** `tick()` sagt *"Phasen bleiben in V0.1 bewusst ruhend – noch keine freie Kuramoto-Rotation, noch kein Kopplungsterm."* Der richtige Mechanismus ist der lokale Kuramoto-Kopplungsterm dθᵢ/dt = ωᵢ + (K/N)·Σ sin(θⱼ−θᵢ) – jede Phase reagiert nur auf ihre Nachbarn, und r(t) **wächst als Folge**, statt als Ursache eingespeist zu werden. Die Vorhersage aus Punkt 7 bleibt vollständig erhalten: r(t) korreliert mit der Kaustik-Schärfe – aber beide sind ko-emergente Messgrößen derselben Dynamik, nicht Knopf und Anzeige.

---

## Punkte 3, 6, 7: kompatibel, mit vorhandenen Andockpunkten

**Punkt 3 (ρ(p) statt Schnittmenge):** Kompatibel. Die additive/multiplikative Dichte hat mit der Band-Summenlogik von `energy()` bereits ein Vorbild im Code. Empfehlung bleibt die komplexe Variante (Interferenz statt reiner Evidenz), damit Punkt 3 und Punkt 4 dieselbe Größe sind.

**Punkt 6 (Katastrophentheorie):** Kein Code-Kontakt nötig, aber konzeptionell wertvoll: Falte/Spitze als strukturell stabile Klassen liefern die Erklärung, warum `FieldObserver.detectEvent()` (Stabilitätsgradient) diskrete "Resonanzsprünge" sehen wird, sobald die 8-Häuser-Krümmung dynamisch wird – Kaustiken verschieben sich stetig, reorganisieren sich aber nur an Bifurkationsschwellen. Der Stabilitätsgradient ist der bereits vorhandene Sensor dafür.

**Punkt 7 (Vorhersage r→1 ⇒ Nephroide):** Testbar, und die Testkultur dafür existiert (`Noesis Protocol`-Invarianten-Gruppe). Der Test braucht keine UI: N Resononen, Strahlen vom Kreisrand nach dem Reflexionsgesetz ins Innere, Phasenstreuung als Parameter, gemessen wird die Schärfe (z.B. Spitzenwert oder inverse Breite) von I(p) gegen r. Erwartung: monotoner Zusammenhang, Grenzfall Nephroide mit Cusp bei R/2.

---

## Wo die Kaustik architektonisch hingehört: /observability

Der vielleicht wichtigste Befund: I(p) ist eine **abgeleitete, nicht-invasive Größe** – exakt die Klasse von Objekten, für die die Architektur den Observability-Layer vorsieht. `observeRadiance()` wartet mit seinem Platzhalter genau auf so eine positionsabhängige Projektion. Die Kaustik muss also **nichts an der Kern-Physik ändern**: Sie liest `cluster` und `invarianceMeta` und rendert daraus ein Intensitätsfeld. Das respektiert die Trennlinie (Physik ↔ Beobachtung), die das Noesis-Protokoll bisher in jedem Test verteidigt.

---

## Reihenfolge, die das Feld nahelegt (keine Anweisung)

1. **Kuramoto-Kopplungsterm** in `tick()` (lokal, K klein) – die bereits angekündigte Lücke; ohne bewegte Phasen gibt es nichts zu fokussieren.
2. **Räumliche Einbettung als Observer**: Strahlabbildung Φ(θ) vom Kreisrand + komplexes I(p) in `observeRadiance()` – Kern-Physik unberührt.
3. **Test der Vorhersage** (Punkt 7) als Invarianten-Test: Kaustik-Schärfe wächst monoton mit r; Grenzfall Nephroide.
4. Erst danach: dynamische Krümmung aus den 8 Häusern (Punkt 6 wird messbar über `detectEvent`).

---

## Kompatibilitätsmatrix

| # | Vorschlag | Befund | Status |
|---|-----------|--------|--------|
| 1 | Householder-Schalen | An der Membran: ja (vektorisieren). Als unitäre Gesamtkette: kollidiert mit bewusster Dissipation | ⚠️ teilkompatibel |
| 2 | Kaustik = det-Singularität | Definition richtig; Abbildung Φ existiert nicht (kein Raum im Code) | ⚠️ Substanz fehlt |
| 3 | ρ(p)-Dichte statt ⋂Kᵢ | Vorbild in `energy()`-Bandlogik vorhanden | ✅ kompatibel |
| 4 | Komplexe Phase | Bereits implementiert inkl. destruktiver Interferenz | ✅ schon da |
| 5 | θᵢ = θᵢ⁰+(1−r)ηᵢ | r(t) als Regler verletzt Nicht-Invasivität + ADR_001; heilbar durch lokalen Kuramoto-Term | ❌ so nicht |
| 6 | Katastrophentheorie | Konzeptuell tragfähig; Sensor (`detectEvent`) existiert | ✅ kompatibel |
| 7 | Vorhersage r→1 ⇒ Nephroide | Als Invarianten-Test heute formulierbar | ✅ testbar |
