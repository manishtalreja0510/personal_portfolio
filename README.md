# Big Bang Portfolio

A scroll-driven cinematic portfolio built with Flutter Web. Scrolling forward plays the Big Bang origin story of the universe — scrolling backward rewinds it in real time.

**Live site:** deployed via Firebase Hosting (`personal-portfolio-universe`)

---

## Concept

The entire site is one page. A global time value `t ∈ [0, 1]` is derived from scroll position, and every animation on the page is a pure function of `t`. This means there are no timers or animation controllers — rewinding scroll literally rewinds the universe.

The story unfolds across 7 eras:

| Era | Scroll range | Scene |
|---|---|---|
| The Singularity | 0–5% | A single pulsing point in the void |
| The Big Bang | 5–15% | Explosion burst; name assembles from particles |
| Stellar Formation | 15–35% | Star field expands; career facts drift as cosmic data |
| Planetary Accretion | 35–65% | Planets orbit — each one is a chapter of work history |
| Age of Civilizations | 65–85% | Skills and projects surface |
| The Present Moment | 85–95% | Current role and tech stack |
| A New Universe | 95–100% | Contact CTA and finale |

---

## Tech stack

- **Flutter Web** — rendering engine
- **GLSL fragment shader** (`shaders/bigbang.frag`) — Big Bang pulse effect
- **`Canvas.drawRawAtlas`** — all particles share a single glow sprite; the entire particle field costs one draw call
- **Adaptive quality** — `QualityController` automatically steps down the particle budget at sustained frame drops
- **Bundled fonts** — Space Grotesk (body) and Orbitron (display) are pre-bundled under `google_fonts/` to avoid first-paint network requests

---

## Project structure

```
lib/
  data/portfolio_data.dart   ← all content lives here (strings, facts, skills)
  engine/                    ← pure Dart simulation logic
    scroll_engine.dart       ← UniverseClock + UniverseSimulation (the tick loop)
    eras.dart                ← Era enum with t-range slices
    particle_engine.dart     ← particle fields and glow atlas
    text_particles.dart      ← name-assembly particle effect
    skill_stars.dart         ← star field seeded from skill strings
    planet_system.dart       ← orbital planet renderer
    career_stream.dart       ← career timeline particle stream
    quality.dart             ← adaptive quality tier
    easter_egg.dart          ← konami-code easter egg
    finale.dart              ← end-of-scroll burst
  ui/                        ← stateless UI components
  universe/                  ← root page, painter, per-era overlay widgets
test/                        ← unit tests for pure engine logic
scripts/
  raisepr.sh                 ← run tests → merge main → push → open PR
  run_tests.sh               ← flutter test with expanded reporter
.github/workflows/
  firebase-hosting.yml       ← CI: build web → deploy to Firebase on push to main
```

---

## Getting started

```bash
# Install dependencies
flutter pub get

# Run in Chrome (dev)
flutter run -d chrome

# Production build
flutter build web --release
# Output lands in build/web/
```

---

## Running tests

```bash
flutter test --reporter=expanded
# or via the script:
./scripts/run_tests.sh
```

---

## Deployment

The site is hosted on Firebase Hosting (project `personal-portfolio-universe`).

**Manual deploy:**
```bash
flutter build web --release
firebase deploy --only hosting --project personal-portfolio-universe
```

**Automatic deploy:** any push to `main` triggers the GitHub Actions workflow in `.github/workflows/firebase-hosting.yml`. It requires a `FIREBASE_SERVICE_ACCOUNT` secret in the repository settings.

---

## Contributing / PR flow

Use the provided script to create a branch, run tests, and open a PR in one step:

```bash
./scripts/raisepr.sh feature/my-change "Short description of the change"
```

This will:
1. Create a new branch from `main`
2. Commit staged changes
3. Merge latest `main`
4. Run all tests (aborts on failure)
5. Push and open a PR via `gh`

---

## Content updates

All user-visible text — name, title, skills, job history, contact info — lives in [`lib/data/portfolio_data.dart`](lib/data/portfolio_data.dart). Edit there; the rendering engine derives everything else from those values.
