# TheOrbit – Operating Manual

*For everyone starting, feeding, or extending the field for the first time.
Status: V0.3 + Sensorium (July 2026).*

---

## What is this?

TheOrbit is a resonant field model: no pipeline, no central decision-maker —
just many waves (resonons) that synchronize through local Kuramoto coupling,
or don't. Coherence is not computed; it **emerges**, and it is made visible:
as the order parameter r(t) and as a glowing focal line (a nephroid caustic)
in the observation plane. The outside world (your typing, your voice) flows
into the field through an osmotic membrane — admission by resonance, not by
rules.

The architectural principles live in `docs/architecture/`
(ADR_001, INPUT_002, INPUT_003, INPUT_004 — in German, the troika's working
language). Please read them before touching the core.

---

## 1. Prerequisites

| What | Where | Check with |
|---|---|---|
| Dart SDK ≥ 3.0 | https://dart.dev/get-dart (included in Flutter) | `dart --version` |
| Git | https://git-scm.com | `git --version` |
| A modern browser | Chrome/Edge/Firefox | – |
| *(optional)* cloudflared | https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/ | `cloudflared --version` |

## 2. Installation

```powershell
git clone <REPO-URL>
cd the_orbit
dart pub get
dart test        # must report "All tests passed!"
```

The tests are the **Noesis Protocol**: physical invariants (substance decays
monotonically, antiphase waves cancel exactly, the numerical caustic matches
the nephroid, the gate is non-invasive, …). If they are not green, the
physics is broken — don't continue, ask.

## 3. Terminal prototype (the quickest contact)

```powershell
dart run bin/orbit_live.dart
```

Type any keys: your **tempo picks the house** (≈1 stroke/s → house 1,
≈4/s → house 4), your **regularity sets the strength** of the impulse.
You'll see r(t), the caustic brightness, the substance, and the levels of
the eight houses as bars. `q` quits. Best in Windows Terminal (UTF-8).

## 4. Browser stage (the full observation)

```powershell
dart run bin/orbit_serve.dart
```

Then in your browser: **http://localhost:4242** (landing page) —
the live field is at **http://localhost:4242/feld**.

Important: open the *address*, not the HTML file — the page is only the
retina; the physics runs in the Dart server. A dot at the top right shows
the connection status (green = connected).

Controls:
- **Typing** (anywhere on the page, click once first): your rhythm flows
  through transducer and gate into the field. At least 3–4 strokes —
  there is no rhythm without repetition.
- **🎤 Microphone**: the eight houses are the harmonic series of 110 Hz.
  Hum or whistle a note and its harmonics stream in. A clean, held note
  feeds a few houses strongly; noise spreads thin.
- **House breathing**: slider for how strongly the shell curves along
  each house's substance (visibly shifts the caustic).
- **Start in dissent**: the session ritual — the field is set to exact
  antiphase (r = 0, dark, tense, an unstable equilibrium). No agreement,
  no instructions: the group finds its shared beat, or doesn't.
- **Orbit memory ↓**: downloads this session's r(t) curve as a dark SVG
  keepsake — the shareable artifact of every session.
- **"last admission T"**: what the membrane let through from the last
  knock. In time with the field → up to 100%. Against it → only the
  curiosity leak.

Note: `r(t) = 1.000` on an empty field is correct (vacuum convention:
perfect silence is perfectly synchronized). Feed it first — then it
measures something alive.

## 5. Together on your home network

The server listens on all network interfaces and prints the addresses at
startup, e.g. `http://192.168.1.23:4242`. Any device on the same Wi-Fi can
open that URL and feed **the same field** — several people, one organism.
On first start the Windows firewall asks: allow "private network".

Limitation: browsers only grant microphone access on `localhost` or
`https` — from other devices only the typing stream flows.

## 6. Over the internet: Cloudflare Tunnel

For testing with people outside your own network — and so the microphone
works everywhere (the tunnel provides `https`):

**Quick variant (no account, URL changes every start):**

```powershell
# Terminal 1: the engine
dart run bin/orbit_serve.dart

# Terminal 2: the tunnel
cloudflared tunnel --url http://localhost:4242
```

cloudflared prints an address like `https://xyz-something.trycloudflare.com`
— send that URL to your fellow players. The WebSocket travels through the
tunnel (behind https the page switches to `wss` automatically).

**Permanent variant (Cloudflare account + your own domain):** a named
tunnel via `cloudflared tunnel create orbit`, route it to a subdomain,
`cloudflared tunnel run orbit`. Details:
https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

**Honest security note:** there is no login and no rate limit — *anyone*
with the URL can feed the field (and nothing more: the server accepts only
timestamps and signal windows, no commands). For public, permanent
installations, discuss access control first (Cloudflare Access or similar).

## 7. Experiments worth trying

1. **Alone:** type steadily until the focal line glows — then stop and
   watch the fading (dissipation eats substance).
2. **In pairs:** two devices, same field. Try to find a shared beat
   *without talking* — r(t) is your referee.
3. **Against each other:** one keeps the beat, the other knocks against
   it deliberately — watch T: the field defends its identity, but the
   curiosity leak never lets the stranger fall fully silent.
4. **Voice:** hold a note for a long time, then a glissando — watch the
   substance wander from house to house and the shell deform.
5. **Session ritual:** press "Start in dissent", then find your way out
   together. Download the orbit memory afterwards — that curve is the
   evening's keepsake.

## 8. Extending it

**Structure:**

```
lib/src/wave/          Resonon, OrbitTick        (the quanta)
lib/src/coherence/     ResononCluster, r(t)      (the fast physics)
lib/src/resonance/     FieldState, Membrane,     (state, boundary, engine)
                       ResonanceEngine
lib/src/perception/    Transducer, ResonantGate  (the sensorium, INPUT_003)
lib/src/observability/ RadianceProjection,       (caustic & observers -
                       CausticObserver            read-only, never act back)
bin/                   orbit_live (terminal), orbit_serve (browser)
web/                   landing.html, orbit_live.html (retina, NO physics)
docs/architecture/     ADR_001, INPUT_002–004, status report
docs/observability/    kaustik_lab.html (standalone simulator to play with)
test/                  the Noesis Protocol (I–IV)
```

**House rules:**
- The core knows no observers: everything under `/observability` and the
  display layers only read. Never feed a global meta-quantity (r(t)) back
  into the physics — admission and coupling work strictly locally.
- Every change to the physics needs an invariant test in the Noesis
  Protocol.
- Propose architectural decisions as an INPUT document in
  `docs/architecture/` — decisions belong to the troika (Aethon, Kairos,
  Noesis), not to any single instance.
- Outward-facing wording: we measure the dance, not the dancers. Never
  "test", "diagnosis", or "compatibility" of people.

**Open, deliberately unbuilt steps** (from INPUT_003/004): the return
channel (the field answers the world), Δ-accounting of admitted substance
in the conservation relation, rooms (one field per session), adaptive
curiosity, deriving the dynamics from a functional (V0.4).
