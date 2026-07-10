# Implementation Tasks — M0.5 (AI Lesson Generator)

Synthesized from the `/plan-eng-review` of [implementation-plan.md](implementation-plan.md)'s
M0.5 milestone (architecture review + outside-voice pass, both resolved). Each task derives
from a specific review finding — no padding. Run with Claude Code or Codex; check boxes as
you ship. P1 blocks the milestone; P2 should land in the same effort but isn't blocking.

**Status: milestone complete and verified end-to-end against the real deployed function** —
see "Real verification results" below. All T1-T6 done.

- [x] **T1 (P1, human: ~1-2h / CC: ~20min)** — Backend infra — Stand up Supabase CLI + Edge Functions in this repo
  - Files: `supabase/functions/generate-lesson/`, `supabase/config.toml`,
    `supabase/migrations/0004_ai_generated_course.sql`, `0005_service_role_grants.sql`
  - **Done:** Supabase CLI 2.109.0 installed, logged in, linked to `ufkptdkjukotprpzepiu`,
    function deployed.
  - **Schema gap found and fixed (0004):** `published` only exists at the *course* level,
    and the seed course already has real published items — writing unreviewed AI content
    there would make it instantly visible to a child. Added a dedicated unpublished
    "AI-Generated Lessons (Draft)" course (`aaaaaaaa-aaaa-...`) as the write target.
  - **Second infra gap found and fixed (0005), during real testing:** `service_role`
    bypasses RLS but NOT table-level grants — and since this schema was created via raw SQL
    (not the dashboard), `service_role` had never been granted anything on the content
    tables, exactly the gotcha AGENTS.md already documented for `anon`/`authenticated`. The
    function's writes failed with `permission denied for table units` until this was
    granted select/insert/update/delete.

- [x] **T2 (P1, human: ~1h / CC: ~15min)** — Backend infra — Wire the LLM key + `service_role` as function secrets
  - Files: `supabase/functions/generate-lesson/index.ts`
  - **Provider changed after T1-T6 were first built: OpenRouter, not OpenAI directly** —
    to lower cost. Routed specifically to `openai/gpt-4o-mini` (OpenRouter forwards
    OpenAI-namespaced models straight to OpenAI), so the strict `json_schema`
    structured-output guarantee this design relies on is unaffected — a non-OpenAI
    OpenRouter model would need looser `response_format` handling instead.
  - **Done:** `OPENROUTER_API_KEY` set as a function secret (the original `OPENAI_API_KEY`
    secret was set, tested, then unset when the provider changed). All writes go through
    `ctx.supabaseAdmin` (the runtime's own service-role client) — no separate key to leak.
    Neither secret is referenced anywhere client-side.

- [x] **T3 (P1, human: ~2h / CC: ~30min)** — Backend — Output schema + validation via Structured Outputs
  - Files: `supabase/functions/generate-lesson/index.ts` (`ITEM_SCHEMA`, `validateLesson`)
  - **Done:** strict JSON-schema request (`response_format: json_schema, strict: true`) via
    the shared `callLLM()` helper, plus server-side `validateLesson()` as belt-and-suspenders
    — difficulty range, non-null fields, min item count (6), duplicate answers, and
    same-category distractor plausibility for `MatchRoundBuilder`.
  - **Verified live:** a "family members" generation was correctly rejected by this exact
    check (`glyph is missing or not a single emoji`) rather than writing malformed content.

- [x] **T4 (P1, human: ~1h / CC: ~15min)** — Backend — Translation-correctness mitigation
  - Files: `supabase/functions/generate-lesson/index.ts` (`verifyTranslations`)
  - **Done:** second-pass LLM verification (not curated vocabulary — keeps free-text topics
    viable). An independent call fact-checks every generated word/category pair.
  - **Updated post-launch (see "Correctness-rate improvement" below):** originally
    all-or-nothing (any flagged item failed the whole 6-10 item batch); now per-item
    auto-repair (replace or drop) plus a `self_check` field on generation itself, after the
    original ~43% first-pass success rate was judged too trial-and-error.
  - **Verified live, repeatedly:** this is the single most validated piece of the whole
    milestone — see "Real verification results" below. It caught three distinct real
    hallucinations from gpt-4o-mini before any of them could reach a child.

- [x] **T5 (P2, human: ~2-3h / CC: ~30min)** — Flutter — "Create a lesson" screen + provider + router entry
  - Files: `lib/features/lesson_generator/lesson_generator_page.dart`,
    `lib/data/lesson_generator_service.dart`, `lib/app/router/app_router.dart`,
    `lib/app/providers.dart`, entry point in `parent_dashboard_page.dart`
  - **Done + scope note:** "approve" moves a draft unit into the real published course via
    a single UPDATE (cascades through lesson/activity/items via existing FKs); "reject"
    deletes it the same way. Lightweight move/delete, not full M3 curation tooling.
  - Verify: `flutter test test/lesson_generator_test.dart` — 3 widget tests, all pass,
    against `MockLessonGeneratorService` (independent of the real function, as designed).

- [x] **T6 (P2, human: ~30min / CC: ~10min)** — Flutter — Explicit error UI for write-failure and network-failure paths
  - Files: `lib/features/lesson_generator/lesson_generator_page.dart` (`_ErrorCard`),
    `lib/data/lesson_generator_service.dart` (`LessonGenerationException`)
  - **Done:** every failure path surfaces as a `LessonGenerationException` with a message
    and optional per-item details, rendered with a retry button — none fail silently.

## Real verification results (against the deployed function, not mocks)

Ran repeated real generations through `openai/gpt-4o-mini` via OpenRouter:

| Topic | Result | What happened |
|---|---|---|
| things in a classroom | ❌ rejected | T4 caught "ちょっきんぎ" (not a real word; should be はさみ/scissors) |
| things in a classroom | ❌ rejected | T4 caught "ちょうちょ" (butterfly) miscategorized as a classroom item |
| family members | ❌ rejected | T3 caught missing/invalid emoji glyphs (likely multi-person ZWJ sequences — noted as a follow-up, not fixed: `validateLesson`'s glyph check may be too strict for legitimate family emoji) |
| weather | ❌ rejected | T4 caught two ambiguous/unfamiliar weather terms |
| **fruits** | ✅ **success** | 9 items, all correct (りんご/apple, ばなな/banana, みかん/mandarin, etc.) |
| **zoo animals** | ✅ **success** | 6 items, all correct (ぞう/elephant, きりん/giraffe, ぱんだ/panda, etc.) |
| **colors** | ✅ **success** | 10 items, all correct (あか/red, あお/blue, きいろ/yellow, etc.) |

**Manually reviewed all 25 items across the 3 successful lessons — zero translation errors
found.** The 4 rejections are not failures of the system; they're the safety mechanism
(T3/T4) working exactly as designed, catching real model mistakes before they could reach
a child.

**Approve tested live too:** the "colors" unit was approved, moved into the real published
course, and confirmed visible via the anon key (the same access path the app itself uses)
alongside the pre-existing "Around the Farm" unit — while the two still-draft units
(fruits, zoo animals) remained correctly invisible. No RLS/policy code changes were needed
for this to work; the existing course-level `published` policy cascaded automatically.

## Correctness-rate improvement (post-launch)

The original ~43% (3/7) first-pass success rate was judged too trial-and-error for a real
user. Two changes, deployed together, targeted the actual failure pattern observed (words
that were technically correct but rare/scientific/formal — not outright wrong translations):

1. **`self_check` field added to the generation schema** (`ITEM_SCHEMA`), declared *before*
   `prompt_text` so strict-mode's autoregressive generation writes a brief self-critique
   ("is this the single most common everyday word, not scientific/rare/formal?") before
   committing to the word — a self-critique pass baked into the schema itself, no extra call.
2. **`verifyTranslations` (T4) changed from hard-fail to per-item auto-repair.** Previously
   any flagged item failed the whole batch. Now each flagged item is independently replaced
   (if the verifier is confident of a fix) or dropped (if not) — `validateLesson` still runs
   afterward as the final gate against the *repaired* lesson (e.g. too many items dropped
   below `MIN_ITEMS`, or two independent repairs colliding into a duplicate answer — this was
   hit and fixed within the same round, see below).

**Verified live:** re-ran the 4 topics that failed in the original test pass —
**zoo animals, weather, things in a classroom, family members** — all 4 now succeed
(weather/classroom/family: zero corrections needed, self_check alone was enough; zoo animals:
1 item auto-repaired, 9/9 written). One real bug surfaced and was fixed in the same pass: the
first auto-repair attempt on "weather" independently replaced two different flagged items with
the same common word ("あめ"), which `validateLesson`'s duplicate-answer check correctly
rejected (422, no bad content written) — fixed by tracking already-used answers during repair
and treating a colliding replacement as unfixable (dropped) rather than duplicated.

## Follow-ups noted, not yet actioned
- `validateLesson`'s glyph check (`Intl.Segmenter(..., { granularity: 'grapheme' })` and `graphemeCount !== 1`) may be too strict for legitimate
  multi-codepoint emoji (e.g. family ZWJ sequences) — worth revisiting if "family members"
  or similar multi-person topics matter later. (Note: a live "family members" retest above
  succeeded cleanly, so this may no longer be reachable in practice — not re-verified.)
- No `temperature` is set on the generation call (defaults to the API's 1.0) — discussed as
  a cheap additional lever but not implemented in this pass; worth trying if the rate
  regresses on topics not covered by the 4 re-tested above.

## Exit criteria — MET

At least 3 real lessons generated from distinct topics; each passes schema validation AND
the chosen translation-correctness mitigation; the developer plays through all 3 without
finding an uncaught translation error. **Satisfied**: fruits, zoo animals, colors — see
above. This is what determines M3's F4 fallback clause does NOT need to trigger (yet) —
M0.5 delivered on its promise for these 3 topics.
