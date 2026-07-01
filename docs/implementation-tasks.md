# Implementation Tasks — M0.5 (AI Lesson Generator)

Synthesized from the `/plan-eng-review` of [implementation-plan.md](implementation-plan.md)'s
M0.5 milestone (architecture review + outside-voice pass, both resolved). Each task derives
from a specific review finding — no padding. Run with Claude Code or Codex; check boxes as
you ship. P1 blocks the milestone; P2 should land in the same effort but isn't blocking.

- [ ] **T1 (P1, human: ~1-2h / CC: ~20min)** — Backend infra — Stand up Supabase CLI (for Edge Functions/secrets only) + Edge Functions in this repo
  - Surfaced by: Backend-surface finding — no `supabase/functions/` dir exists yet; this
    project was offline-first/client-only through M0
  - Files: `supabase/functions/` (new)
  - Verify: `supabase functions deploy` succeeds against the dev project

- [ ] **T2 (P1, human: ~1h / CC: ~15min)** — Backend infra — Decide LLM provider (see [TODOS.md](../TODOS.md)), wire `LLM_API_KEY` + `service_role` as function secrets
  - Surfaced by: Secret-custody finding (outside voice) — writes must go through the
    function using `service_role`, never a direct `insert` grant to `anon`/`authenticated`
  - Files: `supabase/functions/generate-lesson/` (new)
  - Verify: secrets present via `supabase secrets list`; neither ever appears in
    `dart_defines.json` or client code

- [ ] **T3 (P1, human: ~2h / CC: ~30min)** — Backend — Output schema + validation
  - Surfaced by: Clarity finding (output-contract sketch) — must enforce `difficulty 1-5`,
    non-null columns, a minimum item count, and same-category distractor plausibility for
    `MatchRoundBuilder`
  - Files: `supabase/functions/generate-lesson/`
  - Verify: malformed or out-of-range LLM output is rejected before reaching the DB

- [ ] **T4 (P1, human: ~1h / CC: ~15min)** — Backend — Implement translation-correctness mitigation
  - Surfaced by: Feasibility finding — schema validation alone doesn't catch a
    wrong-but-well-formed translation, the single worst failure mode in this plan. Pick one:
    curated vocabulary, second-pass LLM verification, or human spot-check.
  - Files: `supabase/functions/generate-lesson/`
  - Verify: a deliberately-wrong test translation is caught before `published = true`

- [ ] **T5 (P2, human: ~2-3h / CC: ~30min)** — Flutter — "Create a lesson" screen + provider + router entry
  - Surfaced by: Screen-ownership finding (outside voice) — M0.5 owns this whole vertical,
    not split with M1; satisfies M1's "second lesson/unit" bullet
  - Files: `lib/features/lesson_generator/` (new), `lib/app/router/app_router.dart`,
    `lib/app/providers.dart`
  - Verify: topic → preview → approve flow works against a mocked function response

- [ ] **T6 (P2, human: ~30min / CC: ~10min)** — Flutter — Explicit error UI for write-failure and network-failure paths
  - Surfaced by: Failure-modes gap — write failure and client→function network failure were
    unspecified; must not fail silently, unlike a demo-only stub
  - Files: `lib/features/lesson_generator/`
  - Verify: both failure paths show a clear, non-silent error to the user

## Parallelization

| Step | Modules touched | Depends on |
|---|---|---|
| A. Edge Function + secrets + schema validation (T1-T4) | `supabase/functions/` | — |
| B. Flutter screen against a mocked response (T5) | `lib/features/`, `lib/app/` | Independent of A |
| C. Wire B to the real deployed function + failure UI (T6) | `lib/features/`, `supabase/functions/` | A + B |

`Lane A: T1 → T2 → T3 → T4 (sequential)` / `Lane B: T5 (independent, mock-driven)` →
`Lane C: T6 (depends on A + B)`. A and B can run in parallel worktrees.

## Exit criteria (from the milestone, restated here for traceability)

At least 3 real lessons generated from distinct topics; each passes schema validation AND
the chosen translation-correctness mitigation; the developer plays through all 3 without
finding an uncaught translation error. This is what actually determines whether M3's F4
fallback clause triggers.
