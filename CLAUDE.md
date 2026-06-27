# CLAUDE.md

Guidance for Claude Code (and humans) working in this repo.

## What this is
A cross-platform **Flutter** kids' language-learning app (`kids_lang`). Play-first:
children learn vocabulary through tap-to-match mini-games with audio-visual feedback,
adaptive spaced repetition, and offline-first progress that syncs to **Supabase**.
Audience: ages 6–10, mixed home/classroom. Current content teaches **Japanese**
(course `target_language = 'ja'`); the target language is data-driven, not hardcoded.

Status: a working **vertical slice** (one "Animals" lesson, tap-to-match) plus a
"Sprout" visual reskin with extra screens. See [docs/design.md](docs/design.md) for the
full architecture, scope, and what's deferred.

## Run / build / test
Supabase credentials are injected at build time via `--dart-define` (never committed):

```bash
flutter run -d <device> \
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

- The app **boots without** the defines (offline/no-backend mode) for pure UI work.
- Codegen (drift only — see Conventions): `dart run build_runner build --delete-conflicting-outputs`
- Static analysis: `flutter analyze` (keep it clean — CI gate).
- Tests: `flutter test` (SRS unit tests + activity widget tests).

To apply Supabase schema/seed migrations there is **no Supabase CLI**; use a throwaway
Dart `postgres` script. **Direct DB host is IPv6-only and most networks have no IPv6** —
connect through the IPv4 **session pooler**: host `aws-1-<region>.pooler.supabase.com:5432`,
user `postgres.<ref>` (note the `aws-1` prefix). The dev project is `ap-southeast-1`.

## Architecture map
```
lib/
  main.dart                       # bootstrap: init Supabase (if configured) -> runApp
  app/
    app.dart                      # MaterialApp.router
    router/app_router.dart        # go_router: / /map /play /complete /progress /parents
    theme/app_theme.dart          # "Sprout" design tokens + ThemeData (google_fonts)
    providers.dart                # ALL Riverpod providers (plain, no codegen)
  core/
    audio/audio_service.dart      # AudioService (flutter_tts); language is per-call
    speech/speech_service.dart    # SpeechService interface + Unavailable stub (F2, deferred)
    db/app_database.dart(.g.dart) # drift: LocalItemStates (offline cache + outbox flag)
    srs/srs_scheduler.dart        # SM-2-lite spaced repetition (pure Dart, unit-tested)
    supabase/app_supabase.dart    # Env (String.fromEnvironment) + initSupabase()
    sync/connectivity_sync.dart   # drains outbox on reconnect (connectivity_plus)
  domain/models/content.dart      # Course/Unit/Lesson/Activity/Item (plain immutable)
  data/
    content_repository.dart       # reads published content from Supabase (+ target lang)
    results_repository.dart       # ResultsSink: offline-first write + outbox sync (SRS)
  features/
    learner_home/                 # home: greeting, streak, course card, nav
    lesson_map/                   # unit/lesson map
    activity_match/               # the tap-to-match game (page + MatchRoundBuilder)
    round_complete/               # celebration screen (RoundSummary)
    progress/                     # "My Stars" per-item mastery
    parent_dashboard/             # parent metrics (some placeholder data)
supabase/migrations/              # 0001 schema+RLS+grants, 0002 seed, 0003 -> Japanese
test/                             # srs_scheduler_test, activity_match_test
```

## Conventions (follow these)
- **State: plain Riverpod 3 providers** in `app/providers.dart` (`Provider`, `FutureProvider`,
  `StreamProvider`, `Notifier`). We do **NOT** use riverpod_generator — do not add `@riverpod`.
  Use `.value` on `AsyncValue` (Riverpod 3 dropped `valueOrNull`).
- **Models: plain immutable Dart classes** with `fromMap`. We do **NOT** use freezed
  (the dep exists but is unused — dev-channel version was risky). Don't reach for it.
- **build_runner is for drift only.** The only generated file is `app_database.g.dart`.
  Re-run build_runner after changing `app_database.dart`.
- **Secrets via `--dart-define`**, read through `Env` in `core/supabase/app_supabase.dart`.
  No `.env` file, nothing committed. Changing keys requires a rebuild.
- **Pictures are emoji glyphs; audio is on-device TTS.** No binary image/audio assets ship.
  `Item.glyph` holds the emoji; `AudioService.speakWord(text, language:)` speaks via flutter_tts.
  Activity passes `lesson.targetLanguage` (BCP-47, mapped from the course's `target_language`).
- **Offline-first writes.** `ResultsRepository` writes to drift first (`synced=false`), then
  best-effort pushes to Supabase; `ConnectivitySync` drains the outbox on reconnect. Never
  assume the network — failures stay queued, not lost.
- **Accessibility is centralized** in `AppTheme` (large tap targets, readable type,
  colorblind-safe feedback that always pairs color with an icon). Pull tokens from there.
- **RLS needs explicit GRANTs.** Raw-SQL migrations must grant table privileges to
  `anon`/`authenticated` (the dashboard does this automatically; we can't rely on that).

## Gotchas
- **Anonymous auth must be enabled** in the Supabase dashboard (Auth → Sign-in) — the app
  calls `signInAnonymously()`. Without it, content reads still work but sync fails (queues locally).
- **Emulator (Windows):** the x86_64 AVD needs the Android Emulator Hypervisor Driver (AEHD),
  installed with admin rights. `flutter run`'s DDS attach is flaky here — `adb install` +
  `am start` is a reliable alternative.
- More infra notes live in the user-memory files referenced by the design doc.
```
