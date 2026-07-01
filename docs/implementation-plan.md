# Implementation Plan

Phased roadmap from the current prototype to a PRD-complete v1. Each milestone names the
[PRD](PRD.md) features/NFRs it advances; architecture rationale is in [design.md](design.md);
working conventions are in [../AGENTS.md](../AGENTS.md). M0.5's build-ready task breakdown
(from its `/plan-eng-review`) is in [implementation-tasks.md](implementation-tasks.md).

**Legend:** 🟢 done · 🟡 partial · 🔴 not started. PRD refs: **F1** multimedia content,
**F2** multimodal I/O, **F3** adaptive memory, **F4** teacher authoring. NFR shorthand
(all from PRD §3 bullets): **NFR-safety** = safety & privacy · **NFR-offline** = offline ·
**NFR-parent** = parent/guardian dashboard · **NFR-a11y** = accessibility ·
**NFR-perf** = performance · **NFR-parity** = cross-platform parity.

---

## Milestone map

| Milestone | Theme | Stage | Primary PRD coverage |
|---|---|---|---|
| **M0** | Vertical slice (architecture proof) | ✅ done | F1🟡 F2🟡 F3🟢 |
| **M0.5** | AI Lesson Generator | after M0, before M1 | F1(content), F4(reduces) |
| **M1** | Playable MVP | after M0.5 | F1, F2, NFR-parent, NFR-parity, NFR-safety(gate) |
| **M2** | Adaptive & voice | after M1 | F2(speech), F3(depth), NFR-offline, NFR-a11y |
| **M3** | Curation & compliance (v1) | v1 | F4(downscoped), NFR-safety(full), NFR-perf, NFR-a11y(full) |

---

## M0 — Vertical slice ✅ (done)
**Goal:** prove the whole stack end-to-end. **Delivered:** tap-to-match activity (F1🟡, one
interaction type, emoji media), TTS output + caption toggle (F2🟡), per-item results + SM-2
SRS + adaptive ordering + cross-device sync + progress (F3🟢), Supabase schema/RLS/grants,
offline-first results with reconnect outbox (NFR-offline🟡), Android verified on emulator.
**Reuse going forward:** `SrsScheduler`, `AudioService`, `ResultsRepository` outbox pattern,
`AppTheme` tokens, `MatchRoundBuilder`.

---

## M0.5 — AI Lesson Generator
**Goal:** replace hand-authored content with AI-generated lessons, directly reducing what
F4's teacher-CMS needs to cover. Approved via `/office-hours` — see the design doc
("AI Lesson Generator for Nihongo", Approach A: Generator First) for full rationale. This
is **additive scope, not a swap** — it does not shrink M1 (see M1's note below); the
future-authoring-work savings it's meant to produce are speculative until M3 actually
proves out, not a near-term time savings. Placed before M1 because it depends only on M0's
existing schema/player, not on M1's media/iOS/consent work — but it is real, non-trivial
Flutter work in its own right (see below), not a backend-only detour.

**Architecture note — this is the project's first backend/server component.** Every prior
milestone kept Supabase as a sync target only (offline-first, client-driven, per AGENTS.md).
M0.5 introduces a live server-side dependency (a Supabase Edge Function) and a second class
of secret the app has never held before. Treat standing this up — CLI auth, deploy, function
secrets — as its own line of work, not a sub-bullet of "build the generator."

- **Owns the full vertical, one team (not split with M1):** Edge Function + the "Create a
  lesson" screen (new route in `app_router.dart`, new provider in `app/providers.dart`,
  new pending/failed-generation UI state) all ship together in M0.5. M1's "Content: a second
  lesson/unit" bullet (below) is satisfied by this generator, not separate hand-authoring —
  the two are no longer independent bullets.
- **Secret custody — decided, not left open:** writes go through the Edge Function using a
  `service_role` key held **server-side only**, never the client. Do **not** grant `insert`
  on content tables to `anon`/`authenticated` — that would let anyone holding the (embedded,
  extractable) anon key write directly, since RLS alone doesn't stop a role that's been
  granted insert. Two secrets total: the LLM API key and the `service_role` key, both
  function secrets, neither ever in `dart_defines.json` or client code. A leaked
  `service_role` key is a full-database compromise — treat it with more care than any
  secret this project has held so far.
- Define a strict output schema (topic → `Lesson`/`Item`s) respecting existing DB
  constraints (`difficulty 1-5`, non-null columns), with a minimum item count and
  same-category distractors for `MatchRoundBuilder`.
- **Translation-correctness gate is part of the completion bar, not a follow-up:** implement
  at least one mitigation (curated vocabulary, second-pass verification, or human
  spot-check) as part of M0.5 itself — schema validation alone does not catch a
  wrong-but-well-formed translation, and a wrong word taught confidently to a 6–10 year old
  is the single worst failure mode in this entire plan. `published` stays `false` until the
  chosen mitigation has actually run, not just "pending review" in the abstract.
- **Exit criteria (measurable, not a demo-once bar):** at least 3 real lessons generated
  from distinct topics; each passes schema validation AND the chosen translation-correctness
  mitigation; the developer plays through all 3 without finding an uncaught translation
  error. This is the bar that actually determines whether M3's fallback clause (below)
  triggers — "a lesson was generated once" cannot fail it, so it wasn't a real gate.

**Request flow (new — the project's first server round-trip):**
```
Flutter app                Edge Function              External
────────────                ──────────────              ────────
"Create a lesson"
  screen (new provider,
  new router entry)
      │  topic
      ▼
  POST /generate  ───────────►  validate request
                                       │
                                       ▼
                                 call LLM API  ──────────► LLM provider
                                  (LLM_API_KEY,                │
                                   function secret)             │ generated JSON
                                       │◄───────────────────────┘
                                       ▼
                              validate against
                              strict schema ──────► [FAIL] return 4xx,
                                (difficulty 1-5,               screen shows
                                 non-null, min                 retry/error
                                 item count, etc.)              (no silent drop)
                                       │ [PASS]
                                       ▼
                              translation-correctness
                              mitigation (curated vocab /
                              2nd-pass / spot-check)
                                       │
                                       ▼
                              write via service_role  ───────► Supabase
                                (published = false)             (courses/units/
                                       │                          lessons/items)
      ◄────────────────────────────────┘
  preview + approve/
  reject UI
```
Every arrow back to the client needs an explicit error state (timeout, LLM error, schema
failure, write failure) — see Failure modes below; none of these should fail silently.

---

## M1 — Playable MVP
**Goal:** a real lesson a child can complete with genuine media, an iOS build, and a parent
surface backed by real data — shippable to a test family/classroom.

- **F1 · real media + more interactions**
  - Add image/audio support to `Item` (the schema already has `image_url`/`prompt_audio_url`);
    load via Supabase Storage with the emoji glyph as fallback. *(M1 extends/relaxes the
    current AGENTS.md baseline of "emoji glyphs + on-device TTS only" — emoji + TTS remain
    the mandatory fallback when media URLs are absent.)*
  - Add **drag-and-drop** and **sequence** activity types alongside `match` (new `features/*`,
    new `activities.type` values; `MatchRoundBuilder` is the template).
- **F2 · audio polish**
  - Prefer native-speaker `prompt_audio_url` when present, falling back to TTS (extend `AudioService`).
- **NFR-parent dashboard:** replace placeholder metrics with real aggregates from
  `learner_item_states` (time, words mastered, accuracy); add basic screen-time setting.
- **NFR-safety (gate):** minimal **parental-consent gate** before first play (age-gate +
  guardian confirmation); keep anonymous auth underneath for now.
- **NFR-parity:** build + smoke-test on **iOS** (needs a Mac/CI); fix platform gaps.
- **Content:** a second lesson/unit so the lesson map isn't a single node — satisfied by
  M0.5's generator (no separate hand-authoring work here; if M0.5 hasn't shipped by the
  time this is needed, hand-author one as a fallback).
- **Note:** M0.5 is additive to this milestone's scope, not a reduction of it — nothing
  below was cut to make room for the generator.
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

## M3 — Curation & compliance (v1)
**Goal:** teachers can shape content without engineers, and the app is compliant to ship.

- **F4 · teacher curation & override tools (downscoped from full CRUD):** if M0.5's AI
  generator ships and its translation-correctness mitigation holds up, a full from-scratch
  authoring CMS is likely unnecessary. Reframe F4 as role-based **curation** — approve,
  edit, or reject AI-generated lessons; fix a wrong translation; adjust difficulty — rather
  than a ground-up content-creation UI. Role-based access (`profiles.role` exists) and RLS
  tightening so teachers write only their own content still apply either way. **Re-evaluate
  at M3 start against M0.5's actual exit criteria** (3 lessons, all pass validation +
  translation-correctness mitigation, no uncaught errors on playthrough) — if M0.5 never
  shipped, or shipped but the mitigation proved unreliable in practice, fall back to the
  original full-CRUD F4 scope — Course→Unit→Lesson→Activity→Item authoring, media upload,
  preview → version → publish. (Web or in-app teacher mode either way.)
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
  committed; least-privilege RLS; periodic secret-leak scan (as run on this repo). As of
  M0.5, this also covers Edge Function secrets (LLM key, `service_role` key) — same rule,
  new surface: never in client code, never in `dart_defines.json`.
- **Migrations:** every schema change is a numbered file in `supabase/migrations/` with RLS +
  GRANTs; applied via the pooler (see [AGENTS.md](../AGENTS.md)).
- **Backend surface (new as of M0.5):** this project was offline-first/client-only through
  M0 — no server component, Supabase used only as a sync target. M0.5 changes that. Standing
  up Supabase CLI auth + Edge Function deploy is real, one-time setup cost, not a detail
  inside the M0.5 feature work.

## Out of scope (per PRD §4)
Live human tutoring, social/multiplayer, AR — revisit post-v1.
