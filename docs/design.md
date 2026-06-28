# Kids Language-Learning App — Design

A versioned record of the architecture, scope, and decisions. The source requirements are in
[PRD.md](PRD.md); operational conventions and commands live in [../CLAUDE.md](../CLAUDE.md);
this document is the "why".

## 1. Context
A play-first, cross-platform Flutter app that teaches young children (ages 6–10, home and
classroom) vocabulary in a target language through interactive multimedia activities, with
adaptive difficulty and teacher-authored content. Built from a draft PRD (features F1–F4 +
COPPA/GDPR-K table stakes).

The full PRD is large, so the build is deliberately a **vertical slice**: one end-to-end
"tap-to-match" lesson that exercises the whole stack — content → playable activity →
audio-visual feedback → result persistence → spaced-repetition scheduling → progress →
cloud sync — proving the architecture before scaling to every feature. A "Sprout" visual
design (warm cream canvas, leafy-green primary, Fredoka/Nunito, chunky tactile buttons) was
later layered on, adding map/celebration/parent screens around the same core loop.

## 2. Confirmed decisions
- **Deliverable:** scaffold + one vertical slice (not the full feature set).
- **Backend:** Supabase (Postgres + Auth + Storage + Realtime; better data-residency control
  for child-privacy compliance than Firebase).
- **Audience:** ages 6–10, mixed home + classroom; roles (teacher/learner/parent) shaped into
  the data model from the start.
- **Target language:** Japanese (`target_language = 'ja'`), but **data-driven** — the TTS
  language is read from the course and mapped to a BCP-47 tag (`ja-JP`), so switching
  languages is a content change, not a code change.
- **Speech (F2):** on-device-first with opt-in cloud fallback. Interface defined now
  (`SpeechService`), implementation deferred; the slice activity is tap-based.

## 3. Tech stack
Flutter (stable) · Riverpod 3 (plain providers, no codegen) · go_router · supabase_flutter ·
drift + drift_flutter (offline SQLite, the only build_runner consumer) · flutter_tts (audio
out) · flutter_animate (feedback) · google_fonts (Fredoka/Nunito) · connectivity_plus
(reconnect sync). Models are hand-written plain Dart (freezed intentionally unused).

## 4. The vertical slice — "Tap-to-Match"
A child hears a word (TTS) and taps the matching picture (emoji glyph) among large targets.
Covers PRD F1 (tap interaction, big targets, immediate audio+animation feedback), F2 (TTS
output + caption toggle), and F3 (persist result, schedule review, adaptive next-item,
surface progress). Flow:

1. Launch → anonymous Supabase sign-in → seed course loaded from Supabase.
2. Home shows the lesson + a learned badge; child taps Play.
3. `activity_match` plays an audio prompt + a grid of picture options; tap → immediate
   feedback (success = green "せいかい!" + sound; wrong = gentle shake, retry). Attempts and
   response time recorded.
4. On completion `ResultsRepository` writes `learner_item_states` locally (drift) and
   enqueues a Supabase upsert (offline-safe outbox); `SrsScheduler` computes the next due.
5. Adaptive ordering surfaces due/weak items first (`MatchRoundBuilder`).
6. Progress ("My Stars") and the round-complete celebration reflect the result.

## 5. Data model & Supabase
Content hierarchy (PRD F4): `courses → units → lessons → activities → items`, plus
`profiles` (role: teacher/learner/parent) and `learner_item_states` (SRS state). Migrations
in `supabase/migrations/`:
- `0001_init.sql` — tables, **RLS policies**, and **table GRANTs** to `anon`/`authenticated`
  (raw-SQL migrations must grant explicitly; the dashboard would do it automatically).
- `0002_seed.sql` — the sample "Animals" course (now Japanese: ねこ/いぬ/とり/さかな/うし/あひる).
- `0003_seed_japanese.sql` — converts an existing Spanish DB to Japanese in place by replacing
  activity items (new item UUIDs are created, so existing progress links do not carry over);
  idempotent.

Media: emoji glyphs as pictures + on-device TTS, so no binary assets ship in the slice.

**Compliance posture:** anonymous auth stands in for the eventual parental-consent / role-based
sign-in; it gives each device a stable `auth.uid()` for RLS without collecting child data. The
schema/roles are shaped so consent gating and authoring slot in without rework.

## 6. Key components (reuse these)
- `AudioService` (TTS) — every activity speaks through it; language is per-call.
- `SpeechService` — interface now so pronunciation activities drop in later.
- `SrsScheduler` — pure Dart, unit-tested, reused across all item types.
- `ResultsRepository` outbox pattern + `ConnectivitySync` — the template for all offline writes.
- `AppTheme` — central design tokens; enforces accessibility app-wide.

## 7. Out of scope / deferred
Teacher authoring UI (F4), real speech implementation (F2), durable offline **content** caching
(only learner results are offline-durable today), realtime cross-device sync, parental-consent/
COPPA gate, the non-match interaction types (trace/sequence/speak), and wiring the parent
dashboard's placeholder metrics (streak/time/accuracy) to real data.

## 8. Verification
`flutter analyze` clean · `flutter test` green (SRS + activity tests) · debug APK builds ·
runs on the Android emulator end-to-end: content loads from Supabase, the match loop plays,
results persist locally **and** sync to `learner_item_states`, progress updates, and the
offline outbox drains on reconnect (verified by toggling the emulator's network mid-round).
