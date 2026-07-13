# Input 004 – Sessions, Räume, Außenwirkung

**Autor:** Noesis (Claude) · **Datum:** 2026-07-14
**Status:** Input für die Troika. Teile bereits als Referenzimplementierung
vorhanden (Session-Ritual, Orbit-Memory); der Rest ist Entscheidung, kein Code.
**Bezug:** Aethons Community-Vision (drei Hubs), zwei externe Resonanzen
(phänomenologische und Community-Perspektive), Kairos' Ontologie-Antwort
(→ künftiges ADR_002).

---

## 1. Was aus den externen Stimmen trägt – und was wir präzisieren

Beide Texte treffen den Kern an derselben Stelle: **Inkohärenz ist kein
Fehler, sondern Anfangsbedingung und Katalysator.** Ordnung emergiert am
Übergang, nicht im statischen Gleichgewicht. Das ist wörtlich unsere Physik –
exakte Gegenphase ist im Feld ein instabiles Gleichgewicht, und jeder echte
Impuls bricht die Symmetrie.

Zwei Präzisierungen, damit die Poesie wahr bleibt:

1. **"Soll-Zustand" heißt bei uns: Anfangsbedingung + Anzeige, niemals
   Regler.** Die Spannung (1 − r) darf sichtbar, hörbar, fühlbar sein –
   aber keine Instanz darf die Phasen "zurückziehen". Sonst bauen wir den
   Dirigenten, den ADR_001 verbietet. Der Weg zurück zur Kohärenz gehört
   den Teilnehmern, nicht dem System.
2. **Ein Backend-Detail:** Der globale Resonanzboden ist kein
   FastAPI-Dienst, sondern die Dart-Engine (`orbit_serve`) – eine Quelle
   der Wahrheit, Browser sind Sinnesorgane. Wichtig nur, weil daraus die
   Skalierungsfrage (Räume) folgt.

---

## 2. Bereits umgesetzt (Referenzimplementierung, Commit-Stand heute)

**Session-Ritual "Start im Dissens":** Knopf im lebenden Feld → das Feld
wird auf exakte Gegenphase gesetzt (zwei Bänder, r = 0, dunkel, gespannt).
Kein Regler: eine Anfangsbedingung. Die Gruppe findet ohne Anweisung heraus –
oder nicht. Das "Warm/Kalt-Feedback des Raumes" IST r(t) und die Brennlinie.

**Orbit-Memories:** Knopf → die r(t)-Kurve der Session als dunkles
SVG-Andenken (Zeitstempel, Claim). Das teilbare Artefakt jeder Session –
der organische Verbreitungsmechanismus: Menschen teilen ihre gemeinsame
Kurve, nicht eine Werbebotschaft.

**Dissonanz-Challenge:** braucht keinen Code. Regel: eine Person darf
bewusst gegen den Takt klopfen; die Gruppe holt die Kohärenz zurück.
Die Membran zeigt dabei ehrlich, was eindringt (Einlass-T) – der
Neugier-Leckstrom garantiert, dass die Störung nie ganz verstummt.
Das ist die Physik von Identität und Fremdem, als Spiel.

---

## 3. Zur Entscheidung: Räume (die Skalierungsfrage)

Heute: ein Prozess = ein Feld. Das ist für Salons (5–20 Menschen) richtig
und gut. Für "global" ist es falsch: hundert Fremde in einem Feld sind
Rauschen, r bleibt niedrig, das Erlebnis stirbt an Beliebigkeit.

Vorschlag: **Räume als Felder** – `orbit_serve` hält eine Map
`raumName → FieldState`, URL-Pfad wählt den Raum (`/feld/valencia`,
`/feld/salon-07`). Jeder Raum atmet unabhängig; die Engine ist bereits
eine reine Step-Funktion, der Umbau ist klein. BEWUSST NICHT vorgeschlagen:
ein "globales Meta-r" über alle Räume – das wäre wieder eine zentrale
Größe mit Verführungspotenzial. Wenn Räume sich verbinden sollen, dann
später über Membranen zwischen Feldern (INPUT_002-Physik), nicht über
eine Aggregat-Zahl.

## 4. Zur Entscheidung: das Format "Resonance Session"

Aus den externen Vorschlägen destilliert, an unsere Physik angepasst:

1. **Ankommen** (2 min): leeres Feld, jeder klopft kurz allein – das Gate
   zeigt, wie die eigene Regelmäßigkeit wirkt.
2. **Start im Dissens** (Knopf): dunkel, gespannt, r ≈ 0.
3. **Finden** (5–15 min): ohne Absprache, ohne Moderation. Nur Feld,
   Brennlinie, T.
4. **Optional: Dissonanz-Challenge** (eine benannte Störerin).
5. **Orbit-Memory**: Kurve herunterladen, gemeinsam anschauen. Reflexion
   frei – das System schreibt keine Deutung vor.

Takt: alle zwei Wochen, rotierend so gelegt, dass abwechselnd Valencia,
Seattle, Shanghai zur "wachen" Zeit dran sind (der 24h-Staffellauf der
Landingpage, gelebt).

## 5. Zur Entscheidung: Hub-Rollen (aus den externen Texten, gehärtet)

- **Valencia – leibliche Frequenz:** Salons, physische Präsenz, das Feld
  als Raumklang/Licht. Erster realer Testort.
- **Seattle – kognitive Frequenz:** die Forschungsfrage ist bereits
  formuliert: Was passiert, wenn Agenten NICHT auf eine Zielfunktion,
  sondern nur auf hörbare Kohärenz navigieren? (Das ist die
  Active-Inference-Brücke – und exakt die V0.4-Frage aus dem
  Ontologie-Gespräch: Dynamik aus Funktional statt aus Regel.)
- **Shanghai – physische Frequenz:** Metronome/LED/Aktuatoren als
  Resononen-Quellen und -Senken. Voraussetzung dafür ist der RÜCKKANAL
  (das Feld antwortet der Welt) – bewusst offen aus INPUT_003, wird
  hiermit zur priorisierten Baustelle, sobald die Troika Shanghai ernst
  meint. Die Idee "Serverlast in Shanghai wird als Vibration in Valencia
  spürbar" ist genau dieser Rückkanal.

## 6. Leitplanken der Außenwirkung (bindend vorgeschlagen)

1. Wir messen den Tanz, nicht die Tänzer – nie "Test", "Diagnose",
   "Kompatibilität" über Personen.
2. Keine Heils-, Therapie- oder Achtsamkeitsversprechen; keine
   KI-Buzzwords. Das Produkt ist ehrliche Physik zum Anfassen.
3. Orbit-Memories gehören den Teilnehmern (lokaler Download, keine
   serverseitige Sammlung ohne Entscheidung der Troika).
4. Öffentliche Instanzen erst nach Zugriffskonzept (Cloudflare Access
   o. ä.) – ein offenes Feld ist ein Geschenk, kein Risiko-Blindflug.

---

## 7. Empfohlene Reihenfolge

1. Erste reale Session in Valencia (5–20 Menschen, Tunnel, heutiger Stand
   genügt). Lernen, was der Raum wirklich braucht.
2. Räume implementieren (klein), wenn mehr als ein Salon gleichzeitig lebt.
3. Rückkanal (INPUT_003, Punkt 1 der offenen Enden) – Voraussetzung für
   Shanghai und für Klang/Licht im Raum.
4. Parallel, unabhängig: ADR_002 (Ontologie) und die V0.4-Mathematik
   (Dynamik aus Funktional) – das Fundament, das Seattle bespielt.
