# Implementation Plan

Phased roadmap from the current prototype to a PRD-complete v1. Each milestone names the
[PRD](PRD.md) features/NFRs it advances; architecture rationale is in [design.md](design.md);
working conventions are in [../AGENTS.md](../AGENTS.md).

**Legend:** 🟢 done · 🟡 partial · 🔴 not started. PRD refs: **F1** multimedia content,
**F2** multimodal I/O, **F3** adaptive memory, **F4** teacher authoring, **NFR-*** non-functional.

---

## Milestone map

| Milestone | Theme | Stage | Primary PRD coverage |
|---|---|---|---|
| **M0** | Vertical slice (architecture proof) | ✅ done | F1🟡 F2🟡 F3🟢 |
| **M1** | Playable MVP | next | F1, F2, NFR-parent, NFR-parity, NFR-safety(gate) |
| **M2** | Adaptive & voice | after M1 | F2(speech), F3(depth), NFR-offline, NFR-a11y |
| **M3** | Authoring & compliance (v1) | v1 | F4, NFR-safety(full), NFR-perf, NFR-a11y(full) |

---

## M0 — Vertical slice ✅ (done)
**Goal:** prove the whole stack end-to-end. **Delivered:** tap-to-match activity (F1🟡, one
interaction type, emoji media), TTS output + caption toggle (F2🟡), per-item results + SM-2
SRS + adaptive ordering + cross-device sync + progress (F3🟢), Supabase schema/RLS/grants,
offline-first results with reconnect outbox (NFR-offline🟡), Android verified on emulator.
**Reuse going forward:** `SrsScheduler`, `AudioService`, `ResultsRepository` outbox pattern,
`AppTheme` tokens, `MatchRoundBuilder`.

---

## M1 — Playable MVP
**Goal:** a real lesson a child can complete with genuine media, an iOS build, and a parent
surface backed by real data — shippable to a test family/classroom.

- **F1 · real media + more interactions**
  - Add image/audio support to `Item` (the schema already has `image_url`/`prompt_audio_url`);
    load via Supabase Storage with the emoji glyph as fallback.
  - Add **drag-and-drop** and **sequence** activity types alongside `match` (new `features/*`,
    new `activities.type` values; `MatchRoundBuilder` is the template).
- **F2 · audio polish**
  - Prefer native-speaker `prompt_audio_url` when present, falling back to TTS (extend `AudioService`).
- **NFR-parent dashboard:** replace placeholder metrics with real aggregates from
  `learner_item_states` (time, words mastered, accuracy); add basic screen-time setting.
- **NFR-safety (gate):** minimal **parental-consent gate** before first play (age-gate +
  guardian confirmation); keep anonymous auth underneath for now.
- **NFR-parity:** build + smoke-test on **iOS** (needs a Mac/CI); fix platform gaps.
- **Content:** a second lesson/unit so the lesson map isn't a single node.
- **Exit criteria:** a child completes ≥2 lessons with real media on both iOS and Android;
  parent dashboard shows true numbers; `flutter test` + analyze green; consent gate enforced.

## M2 — Adaptive & voice
**Goal:** the app listens and adapts — the differentiating F2/F3 depth.

- **F2 · speech input (on-device first):** implement `SpeechService` (the interface already
  exists) with platform speech recognition; add a "say the word" activity.
- **F3 · pronunciation scoring:** populate `learner_item_states.pronunciation_score`; feed it
  into the SRS quality signal in `SrsScheduler`.
- **F3 · difficulty depth:** use `nextDifficulty` to actively steer item selection across
  difficulty bands; tune intervals from real data.
- **NFR-offline (content):** durable offline **content/media** caching (extend drift beyond
  results; pre-download a lesson's media).
- **NFR-a11y:** full **"no-reading" mode** — voice prompts replace all text for pre-readers.
- **Exit criteria:** pronunciation activity works offline on-device; scores influence
  scheduling; a lesson is fully playable with no network and no on-screen text.

## M3 — Authoring & compliance (v1)
**Goal:** teachers create content without engineers, and the app is compliant to ship.

- **F4 · teacher authoring system:** role-based access (teacher/learner/parent — `profiles.role`
  exists); CRUD over Course→Unit→Lesson→Activity→Item; media upload; **preview → version →
  publish** workflow; tighten RLS so teachers write only their content. (Web or in-app teacher mode.)
- **NFR-safety (full):** COPPA + GDPR-K compliance — real auth/identity, data-minimization
  review, no behavioral ads, kidSAFE-style posture; replace the M1 stub gate.
- **NFR-performance:** verify 60fps animations, media caching, fast cold start.
- **NFR-a11y (full):** colorblind-safe audit, audio cues throughout, large-target audit.
- **Exit criteria:** a teacher authors + publishes a lesson that a learner plays; compliance
  checklist signed off; performance budget met on low-end devices.

---

## Cross-cutting (every milestone)
- **Testing/CI:** keep `flutter analyze` clean and `flutter test` green; add widget tests per
  new activity type and a GitHub Actions workflow (analyze + test on PRs).
- **Security/privacy:** secrets stay in `dart_defines.json` (gitignored) / CI secrets — never
  committed; least-privilege RLS; periodic secret-leak scan (as run on this repo).
- **Migrations:** every schema change is a numbered file in `supabase/migrations/` with RLS +
  GRANTs; applied via the pooler (see [AGENTS.md](../AGENTS.md)).

## Out of scope (per PRD §4)
Live human tutoring, social/multiplayer, AR — revisit post-v1.
