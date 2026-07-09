# TheOrbit – Betriebsanleitung

*Für alle, die das Feld zum ersten Mal starten, füttern oder weiterentwickeln
wollen. Stand: V0.3 + Sensorium (Juli 2026).*

---

## Was ist das hier?

TheOrbit ist ein resonantes Feldmodell: keine Pipeline, kein zentraler
Entscheider, sondern viele Wellen (Resononen), die sich über lokale
Kuramoto-Kopplung synchronisieren – oder eben nicht. Kohärenz wird nicht
berechnet, sie **emergiert** und wird sichtbar gemacht: als Ordnungsparameter
r(t) und als aufleuchtende Brennlinie (Nephroiden-Kaustik) in der
Beobachtungsebene. Die Außenwelt (dein Tippen, deine Stimme) fließt durch
eine osmotische Membran ins Feld – Einlass nach Resonanz, nicht nach Regeln.

Die Architektur-Grundsätze stehen in `docs/architecture/`
(ADR_001, INPUT_002, INPUT_003) – bitte lesen, bevor am Kern geschraubt wird.

---

## 1. Voraussetzungen

| Was | Woher | Prüfen mit |
|---|---|---|
| Dart SDK ≥ 3.0 | https://dart.dev/get-dart (in Flutter enthalten) | `dart --version` |
| Git | https://git-scm.com | `git --version` |
| Moderner Browser | Chrome/Edge/Firefox | – |
| *(optional)* cloudflared | https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/ | `cloudflared --version` |

## 2. Installation

```powershell
git clone <REPO-URL>
cd the_orbit
dart pub get
dart test        # muss "All tests passed!" melden
```

Die Tests sind das **Noesis-Protokoll**: physikalische Invarianten
(Substanz fällt monoton, gegenphasige Wellen löschen sich aus, die numerische
Kaustik trifft die Nephroide, das Gate ist nicht-invasiv, …). Wenn sie nicht
grün sind, ist die Physik verletzt – nicht weitermachen, sondern fragen.

## 3. Terminal-Prototyp (der schnellste Kontakt)

```powershell
dart run bin/orbit_live.dart
```

Tippe beliebige Tasten: dein **Tempo wählt das Haus** (≈1 Anschlag/s → Haus 1,
≈4/s → Haus 4), deine **Gleichmäßigkeit bestimmt die Stärke** des Impulses.
Du siehst r(t), die Kaustik-Helligkeit, die Substanz und die Pegel der acht
Häuser als Balken. `q` beendet. Am besten im Windows Terminal (UTF-8).

## 4. Browser-Bühne (die volle Beobachtung)

```powershell
dart run bin/orbit_serve.dart
```

Dann im Browser: **http://localhost:4242**

Wichtig: die *Adresse* öffnen, nicht die HTML-Datei – die Seite ist nur die
Netzhaut, die Physik läuft im Dart-Server. Oben rechts zeigt ein Punkt den
Verbindungsstatus (grün = verbunden).

Bedienung:
- **Tippen** (irgendwo auf der Seite, vorher einmal klicken): der Rhythmus
  fließt durch Transducer und Gate ins Feld. Mindestens 3–4 Anschläge,
  sonst gibt es keinen Rhythmus.
- **🎤 Mikrofon**: die acht Häuser sind die Obertonreihe von 110 Hz. Einen
  Ton summen oder pfeifen = seine Harmonischen strömen ein. Ein gehaltener,
  sauberer Ton füttert wenige Häuser stark; Rauschen verteilt sich dünn.
- **Häuser-Atmung**: Regler dafür, wie stark sich die Schale nach der
  Substanz der Häuser krümmt (verschiebt sichtbar die Kaustik).
- **"letzter Einlass T"**: was die Membran vom letzten Klopfen durchgelassen
  hat. Im Takt des Feldes → bis 100 %. Dagegen → nur der Neugier-Leckstrom.

Hinweis: `r(t) = 1.000` bei leerem Feld ist korrekt (Vakuum-Konvention:
perfekte Stille ist perfekt synchron). Erst füttern, dann misst es Leben.

## 5. Gemeinsam im Heimnetz

Der Server lauscht auf allen Netzwerk-Schnittstellen und gibt beim Start
die Adressen aus, z. B. `http://192.168.1.23:4242`. Jedes Gerät im selben
WLAN kann diese URL öffnen und **dasselbe Feld** mitfüttern – mehrere
Menschen, ein Organismus. Beim ersten Start fragt die Windows-Firewall:
"Privates Netzwerk" zulassen.

Einschränkung: das Mikrofon geben Browser nur auf `localhost` oder `https`
frei – im Heimnetz fließt von anderen Geräten also nur der Tipp-Strom.

## 6. Über das Internet: Cloudflare Tunnel

Für Tests mit Leuten außerhalb des eigenen Netzes – und damit das Mikrofon
überall funktioniert (der Tunnel liefert `https`):

**Schnellvariante (ohne Konto, URL wechselt bei jedem Start):**

```powershell
# Terminal 1: die Engine
dart run bin/orbit_serve.dart

# Terminal 2: der Tunnel
cloudflared tunnel --url http://localhost:4242
```

cloudflared druckt eine Adresse wie
`https://xyz-irgendwas.trycloudflare.com` – diese URL an die Mitspieler
schicken. WebSocket läuft durch den Tunnel mit (die Seite wechselt hinter
https automatisch auf `wss`).

**Dauerhafte Variante (mit Cloudflare-Konto und eigener Domain):**
benannter Tunnel per `cloudflared tunnel create orbit`, Route auf eine
Subdomain, `cloudflared tunnel run orbit`. Details:
https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

**Ehrliche Sicherheitsnotiz:** Es gibt keine Anmeldung und keine Begrenzung –
*jeder* mit der URL kann das Feld füttern (mehr kann er nicht: der Server
nimmt nur Zeitstempel und Signalfenster entgegen, keine Befehle). Für
öffentliche Dauer-Installationen vorher über Zugriffsschutz reden
(Cloudflare Access o. ä.).

## 7. Experimente, die sich lohnen

1. **Allein:** gleichmäßig tippen, bis die Brennlinie leuchtet – dann
   aufhören und dem Verklingen zusehen (Dissipation frisst Substanz).
2. **Zu zweit:** zwei Geräte, gleiches Feld. Versucht, *ohne Absprache* in
   einen gemeinsamen Takt zu finden – r(t) ist euer Schiedsrichter.
3. **Gegeneinander:** einer hält den Takt, der andere klopft bewusst
   dagegen – beobachtet T: das Feld verteidigt seine Identität, aber der
   Neugier-Leckstrom lässt das Fremde nie ganz verstummen.
4. **Stimme:** einen Ton lange halten, dann ein Glissando – zusehen, wie
   die Substanz von Haus zu Haus wandert und die Schale sich verformt.

## 8. Weiterentwickeln

**Struktur:**

```
lib/src/wave/          Resonon, OrbitTick        (die Quanten)
lib/src/coherence/     ResononCluster, r(t)      (die schnelle Physik)
lib/src/resonance/     FieldState, Membrane,     (Zustand, Grenze, Engine)
                       ResonanceEngine
lib/src/perception/    Transducer, ResonantGate  (das Sensorium, INPUT_003)
lib/src/observability/ RadianceProjection,       (Kaustik & Beobachter -
                       CausticObserver            liest nur, wirkt nie zurück)
bin/                   orbit_live (Terminal), orbit_serve (Browser)
web/                   orbit_live.html (Netzhaut, KEINE Physik)
docs/architecture/     ADR_001, INPUT_002, INPUT_003
docs/observability/    kaustik_lab.html (Standalone-Simulator zum Spielen)
test/                  das Noesis-Protokoll (I–IV)
```

**Regeln des Hauses:**
- Der Kern kennt keine Beobachter: alles unter `/observability` und die
  Anzeige-Schichten lesen nur. Niemals eine globale Metagröße (r(t)) in
  die Physik zurückführen – Einlass und Kopplung arbeiten strikt lokal.
- Jede Physik-Änderung braucht einen Invarianten-Test im Noesis-Protokoll.
- Architektur-Entscheidungen als INPUT-Dokument in `docs/architecture/`
  vorschlagen – die Entscheidung liegt bei der Troika (Aethon, Kairos,
  Noesis), nicht bei einer Einzelinstanz.

**Offene, bewusst noch nicht gebaute Schritte** (aus INPUT_003):
Rückkanal (das Feld antwortet der Welt), Δ-Buchhaltung der eingelassenen
Substanz in der Erhaltungsrelation, adaptive Neugier, Flutter-App mit
gerenderter Kaustik.
