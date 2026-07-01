# Implementation Tasks — M0.5 (AI Lesson Generator)

Synthesized from the `/plan-eng-review` of [implementation-plan.md](implementation-plan.md)'s
M0.5 milestone (architecture review + outside-voice pass, both resolved). Each task derives
from a specific review finding — no padding. Run with Claude Code or Codex; check boxes as
you ship. P1 blocks the milestone; P2 should land in the same effort but isn't blocking.

- [x] **T1 (P1, human: ~1-2h / CC: ~20min)** — Backend infra — Stand up Supabase CLI (for Edge Functions/secrets only) + Edge Functions in this repo
  - Surfaced by: Backend-surface finding — no `supabase/functions/` dir exists yet; this
    project was offline-first/client-only through M0
  - Files: `supabase/functions/` (new), `supabase/config.toml` (new, `supabase init`),
    `supabase/migrations/0004_ai_generated_course.sql` (new)
  - **Done:** Supabase CLI 2.109.0 installed; `supabase/functions/generate-lesson/`
    scaffolded. **Schema gap found and fixed:** `published` only exists at the *course*
    level, and the existing seed course is already published with real items — writing
    unreviewed AI content there would make it instantly visible to a child. Added migration
    `0004` creating a dedicated unpublished "AI-Generated Lessons (Draft)" course
    (`aaaaaaaa-aaaa-...`) as the write target; applied to the dev DB.
  - **Still open — needs your interactive login:** `supabase login` (browser-based auth),
    then `supabase link --project-ref ufkptdkjukotprpzepiu` and `supabase functions deploy
    generate-lesson`. I can't do the browser auth step for you.

- [x] **T2 (P1, human: ~1h / CC: ~15min)** — Backend infra — **Provider: OpenAI (decided).** Wire `OPENAI_API_KEY` + `service_role` as function secrets
  - Surfaced by: Secret-custody finding (outside voice) — writes must go through the
    function using `service_role`, never a direct `insert` grant to `anon`/`authenticated`
  - Files: `supabase/functions/generate-lesson/index.ts`
  - **Done:** function code uses `ctx.supabaseAdmin` (the Supabase runtime's own
    service-role client — no separate key to manage/leak) for all writes; reads
    `OPENAI_API_KEY` from `Deno.env`. Neither secret is referenced anywhere client-side.
  - **Still open:** actually setting `OPENAI_API_KEY` as a function secret
    (`supabase secrets set OPENAI_API_KEY=...`) — needs your key and the login above.

- [x] **T3 (P1, human: ~2h / CC: ~30min)** — Backend — Output schema + validation, using OpenAI's Structured Outputs (`response_format: json_schema`, `strict: true`)
  - Surfaced by: Clarity finding (output-contract sketch) — must enforce `difficulty 1-5`,
    non-null columns, a minimum item count, and same-category distractor plausibility for
    `MatchRoundBuilder`
  - Files: `supabase/functions/generate-lesson/index.ts` (`ITEM_SCHEMA`, `validateLesson`)
  - **Done:** strict JSON-schema request to OpenAI, plus server-side `validateLesson()` as
    belt-and-suspenders — checks difficulty range, non-null fields, min item count (6),
    duplicate answers, and same-category distractor plausibility (≥half the items share a
    category with another item, so `MatchRoundBuilder`'s random distractor pick isn't
    trivially obvious).

- [x] **T4 (P1, human: ~1h / CC: ~15min)** — Backend — Implement translation-correctness mitigation
  - Surfaced by: Feasibility finding — schema validation alone doesn't catch a
    wrong-but-well-formed translation, the single worst failure mode in this plan
  - Files: `supabase/functions/generate-lesson/index.ts` (`verifyTranslations`)
  - **Done:** chose second-pass LLM verification (not curated vocabulary — keeps free-text
    topics viable, resolving the tension flagged in the design doc's Open Questions) — an
    independent OpenAI call fact-checks every generated word/category pair and fails the
    whole generation (422, with per-item issues) if anything looks wrong or ambiguous.

- [x] **T5 (P2, human: ~2-3h / CC: ~30min)** — Flutter — "Create a lesson" screen + provider + router entry
  - Surfaced by: Screen-ownership finding (outside voice) — M0.5 owns this whole vertical,
    not split with M1; satisfies M1's "second lesson/unit" bullet
  - Files: `lib/features/lesson_generator/lesson_generator_page.dart` (new),
    `lib/data/lesson_generator_service.dart` (new), `lib/app/router/app_router.dart`,
    `lib/app/providers.dart`, entry point added to `parent_dashboard_page.dart`
  - **Done + scope note:** the "approve" step needed to be real, not a stub, given the
    course-level-only `published` flag from T1 — approve now calls the function again
    (`action: "approve"`) which moves the draft unit into the real published course via a
    single UPDATE (cascades through lesson/activity/items via existing FKs); reject deletes
    it the same way. This is a lightweight move/delete, not full M3 curation tooling
    (no edit-before-publish, no rejection reasons) — that distinction is preserved.
  - Verify: `flutter test test/lesson_generator_test.dart` — 3 widget tests, all pass
    (topic→preview→approve, reject, and the T6 error path below), against
    `MockLessonGeneratorService`.

- [x] **T6 (P2, human: ~30min / CC: ~10min)** — Flutter — Explicit error UI for write-failure and network-failure paths
  - Surfaced by: Failure-modes gap — write failure and client→function network failure were
    unspecified; must not fail silently, unlike a demo-only stub
  - Files: `lib/features/lesson_generator/lesson_generator_page.dart` (`_ErrorCard`),
    `lib/data/lesson_generator_service.dart` (`LessonGenerationException`)
  - **Done:** every failure path (network unreachable, generation failure, schema
    validation failure, translation-verification failure, DB write failure, approve/reject
    failure) surfaces as a `LessonGenerationException` with a message and optional
    per-item details, rendered in a dedicated error card with a retry button — none of
    these fail silently. Covered by the `flutter test` case above.

## What's left before this milestone can actually be used

Everything code-side is done and tested against mocks/local validation. What remains needs
you, specifically, since it's either interactive auth or your own API key:

1. `supabase login` (opens a browser)
2. `supabase link --project-ref ufkptdkjukotprpzepiu`
3. `supabase secrets set OPENAI_API_KEY=<your key>`
4. `supabase functions deploy generate-lesson`
5. Then the M0.5 exit criteria below can actually be attempted for real.

## Parallelization (as executed)

Lane A (T1→T4, backend) and Lane B (T5, Flutter against a mock) were built in this session
without needing the real deployed function — matching the plan's intended parallel split.
Lane C (wiring B to the real function) is blocked only on the login step above.

## Exit criteria (from the milestone, restated here for traceability)

At least 3 real lessons generated from distinct topics; each passes schema validation AND
the chosen translation-correctness mitigation; the developer plays through all 3 without
finding an uncaught translation error. This is what actually determines whether M3's F4
fallback clause triggers. **Not yet attempted** — needs the deploy steps above first.
