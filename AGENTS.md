# AGENTS.md

Canonical guidance for AI coding agents working in this repo (Claude Code, Cursor,
Copilot, Codex, etc.). `CLAUDE.md` imports this file; `.github/copilot-instructions.md`
summarizes it. Edit **this** file — the others point here.

## What this is
A cross-platform **Flutter** kids' language-learning app (`kids_lang`, repo "Nihongo").
Play-first: children learn vocabulary through tap-to-match mini-games with audio-visual
feedback, adaptive spaced repetition, and offline-first progress that syncs to **Supabase**.
Audience: ages 6–10, mixed home/classroom. Current content teaches **Japanese**
(`target_language = 'ja'`); the target language is data-driven, not hardcoded.

Status: a working **vertical slice** (one "Animals" lesson, tap-to-match) plus a "Sprout"
visual reskin with extra screens. Requirements: [docs/PRD.md](docs/PRD.md). Architecture and
scope: [docs/design.md](docs/design.md).

## Run / build / test
Supabase credentials are injected at build time and **never committed**. Preferred: a
gitignored `dart_defines.json` (copy `dart_defines.example.json`) consumed via
`--dart-define-from-file`:

```bash
flutter run -d <device> --dart-define-from-file=dart_defines.json
# or pass inline: --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

- The app **boots without** the defines (offline/no-backend mode) for pure UI work.
- Codegen (drift only — see Conventions): `dart run build_runner build --delete-conflicting-outputs`
- Static analysis: `flutter analyze` (keep clean — CI gate).
- Tests: `flutter test` (SRS unit tests + activity widget tests).
- Emulator run helper: the `/run` Claude Code command (`.claude/commands/run.md`).

Applying Supabase **migrations** (`supabase/migrations/`): keep using a throwaway Dart
`postgres` script against the pooler — this predates the CLI below and is proven.
**The direct DB host is IPv6-only and most networks have no IPv6** — connect through
the IPv4 **session pooler**: `aws-1-<region>.pooler.supabase.com:5432`, user `postgres.<ref>`
(note the `aws-1` prefix). The dev project is `ap-southeast-1`.

**Supabase CLI** (installed as of M0.5, via `npm install -g supabase`) is used only for
**Edge Functions** (`supabase/functions/`) — deploy, secrets, and local `supabase init`
scaffolding. It needs an interactive `supabase login` (browser auth) that an agent can't
do on your behalf; migrations still go through the script above, not `supabase db push`.

## gstack
This repo uses [gstack](https://github.com/garrytan/gstack) — a suite of engineering-workflow
skills for AI coding agents. It is **per-developer**, installed into your agent's skills dir,
not vendored here:

```bash
git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
cd ~/.claude/skills/gstack && ./setup   # requires `bun`; on Windows re-run after every `git pull`
```

- **Web browsing: always use the `/browse` skill.** Do **NOT** use the
  `mcp__claude-in-chrome__*` tools.
- Available skills: `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`,
  `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`,
  `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`,
  `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`,
  `/setup-deploy`, `/setup-gbrain`, `/retro`, `/investigate`, `/document-release`,
  `/document-generate`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`,
  `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`,
  `/learn`.

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
  features/{learner_home, lesson_map, activity_match, round_complete, progress, parent_dashboard}
supabase/migrations/              # 0001 schema+RLS+grants, 0002 seed, 0003 -> Japanese
test/                             # srs_scheduler_test, activity_match_test
```

## Conventions (follow these)
- **State: plain Riverpod 3 providers** in `app/providers.dart` (`Provider`, `FutureProvider`,
  `StreamProvider`, `Notifier`). Do **NOT** add riverpod_generator / `@riverpod`. Use `.value`
  on `AsyncValue` (Riverpod 3 dropped `valueOrNull`).
- **Models: plain immutable Dart classes** with `fromMap`. Do **NOT** use freezed (the dep
  exists but is intentionally unused).
- **build_runner is for drift only.** The only generated file is `app_database.g.dart`.
- **Secrets via dart-define**, read through `Env` in `core/supabase/app_supabase.dart`. No
  `.env`. Changing keys requires a rebuild.
- **Pictures are emoji glyphs; audio is on-device TTS.** No binary image/audio assets ship.
  `Item.glyph` holds the emoji; `AudioService.speakWord(text, language:)` speaks via flutter_tts.
  The activity passes `lesson.targetLanguage` (BCP-47, mapped from the course `target_language`).
- **Offline-first writes.** `ResultsRepository` writes to drift first (`synced=false`), then
  best-effort pushes to Supabase; `ConnectivitySync` drains the outbox on reconnect. Never
  assume the network — failures stay queued, not lost.
- **Accessibility is centralized** in `AppTheme` (large tap targets, readable type,
  colorblind-safe feedback that always pairs color with an icon). Pull tokens from there.
- **RLS needs explicit GRANTs.** Raw-SQL migrations must grant table privileges to
  `anon`/`authenticated` (the dashboard does this automatically; we can't rely on that).

## Gotchas
- **Anonymous auth must be enabled** in the Supabase dashboard — the app calls
  `signInAnonymously()`. Without it, content reads still work but sync fails (queues locally).
- **Emulator (Windows):** the x86_64 AVD needs the Android Emulator Hypervisor Driver (AEHD),
  installed with admin rights. `flutter run`'s DDS attach is flaky here — `adb install` +
  `am start` is a reliable alternative (see `.claude/commands/run.md`).
- The parent dashboard's metrics (streak/time/accuracy) are currently **placeholder data**.
