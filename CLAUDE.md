# Big Bang Portfolio — Claude Context

## What this project is

Flutter web portfolio for **Manish Talreja** (Mobile Application Developer · Flutter, Indore, India). The entire site is a scroll-driven cinematic universe: scrolling forward plays the Big Bang origin story; scrolling backward literally rewinds it. Deployed to Firebase Hosting at project `personal-portfolio-universe`.

## Architecture in one paragraph

A single `UniversePage` widget owns a fullscreen `CustomPaint` (the "universe") and an invisible `SingleChildScrollView` layered on top (the input source). Scroll offset is read by `UniverseClock` (→ `lib/engine/scroll_engine.dart`) and converted into a global time `t ∈ [0, 1]`. Every frame, `UniverseSimulation.tick(dt)` advances `t` via exponential smoothing (mouse wheel → cinematic motion), then calls `UniversePainter` to redraw the world. All animations are pure functions of `t` — no `AnimationController`, no timers.

## Directory map

```
lib/
  data/portfolio_data.dart   — all user-visible strings and content (edit here, never in UI)
  engine/
    eras.dart                — Era enum: 7 named eras, each owns a [start, end] slice of t
    scroll_engine.dart       — UniverseClock (scroll → t), UniverseSimulation (tick loop)
    particle_engine.dart     — particle fields, glow sprite atlas, Big Bang burst
    text_particles.dart      — name-assembly particle effect ("MANISH")
    skill_stars.dart         — star field seeded from skill strings
    planet_system.dart       — orbital planet renderer
    career_stream.dart       — scrolling career timeline particles
    easter_egg.dart          — konami-code triggered effect
    finale.dart              — end-of-scroll "new universe" animation
    quality.dart             — adaptive quality tier (drops at sustained jank)
  ui/
    cosmic_scrubber.dart     — scrubber bar to jump between eras
    era_heading.dart         — crossfading era title overlay
    motion_toggle.dart       — reduced-motion preference toggle
    scroll_passthrough.dart  — transparent widget that forwards scroll events
  universe/
    universe_page.dart       — root widget, assembles all layers
    universe_painter.dart    — CustomPainter, orchestrates all engine draw calls
    eras/                    — per-era overlay widgets (hero, stellar, planetary, civilizations, present, contact, finale)
test/                        — unit tests for pure engine logic (no widget tests)
scripts/
  raisepr.sh                 — run tests → merge main → push → open PR
  run_tests.sh               — runs all flutter tests with expanded reporter
.github/workflows/
  firebase-hosting.yml       — CI: flutter build web --release → firebase deploy on push to main
shaders/bigbang.frag         — GLSL fragment shader for the Big Bang pulse effect
google_fonts/                — bundled OFL-licensed fonts (no runtime fetch)
```

## The 7 Eras (scroll time slices)

| Era | t range | What happens |
|---|---|---|
| `singularity` | 0.00–0.05 | Black screen, pulsing singularity dot, "In the beginning…" |
| `bigBang` | 0.05–0.15 | Explosion burst, MANISH assembled from particles |
| `stellar` | 0.15–0.35 | Star field expands, cosmic facts drift as stars |
| `planetary` | 0.35–0.65 | Planets orbit — each planet = one job/project era |
| `civilizations` | 0.65–0.85 | Skills and projects surface as civilizations |
| `present` | 0.85–0.95 | Current role and tech stack |
| `newUniverse` | 0.95–1.00 | Contact CTA, finale burst |

## Key invariants

- **`portfolio_data.dart` is the single source of truth for all content.** UI and engine files never hardcode strings, names, or facts.
- All animation is a **pure function of `t`** — no hidden state, no timers. Rewinding scroll rewinds visuals exactly.
- The particle atlas uses **one draw call** for all particles (`Canvas.drawRawAtlas`). Don't add per-particle paint calls.
- `QualityController` automatically steps down the particle budget at sustained jank. Don't hardcode particle counts — use `starBudget(size)`.
- Fonts are **bundled in `google_fonts/`** to avoid first-paint network requests. Add new fonts there, not via runtime fetch.

## Running and testing

```bash
flutter pub get
flutter run -d chrome          # dev
flutter build web --release    # production (output: build/web)
flutter test --reporter=expanded
```

## Deployment

- **Hosting**: Firebase project `personal-portfolio-universe`, public dir `build/web`
- **CI**: `.github/workflows/firebase-hosting.yml` — triggers on push to `main`, builds Flutter web, deploys via `FIREBASE_SERVICE_ACCOUNT` GitHub secret
- **PR flow**: `scripts/raisepr.sh <branch> "message"` — runs tests, merges latest main, pushes, opens PR via `gh`

## Dependencies

| Package | Purpose |
|---|---|
| `google_fonts` | Space Grotesk (body) + Orbitron (display) |
| `url_launcher` | Email/social links in contact overlay |
| `shared_preferences` | Persist reduced-motion toggle across sessions |

## What NOT to do

- Don't add content to UI files — all copy goes in `portfolio_data.dart`
- Don't introduce `AnimationController` — scroll clock drives everything
- Don't add per-particle draw calls — use the atlas
- Don't fetch fonts at runtime — bundle them under `google_fonts/`
