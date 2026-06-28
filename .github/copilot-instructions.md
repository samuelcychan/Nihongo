# Copilot instructions — Nihongo (Flutter + Supabase)

Full guidance is in [`AGENTS.md`](../AGENTS.md); this is the short version.

A play-first kids' Japanese-learning Flutter app: tap-to-match game, on-device TTS,
SM-2 spaced repetition, offline-first sync to Supabase.

Key conventions (do not violate):
- **Plain Riverpod 3 providers** in `lib/app/providers.dart` — no riverpod_generator / `@riverpod`.
  Use `.value` on `AsyncValue` (no `valueOrNull` in Riverpod 3).
- **Plain immutable Dart models** with `fromMap` — do NOT use freezed (dep is unused).
- **build_runner is for drift only** (`lib/core/db/app_database.g.dart`).
- **Secrets via `--dart-define`** read through `Env` in `lib/core/supabase/app_supabase.dart`.
  Never hardcode or commit Supabase keys; there is no `.env`.
- **Pictures = emoji glyphs, audio = flutter_tts** (no binary assets). Activity speaks in
  `lesson.targetLanguage` (BCP-47 mapped from the course `target_language`).
- **Offline-first writes**: `ResultsRepository` writes drift first, then best-effort syncs;
  `ConnectivitySync` drains the outbox on reconnect.
- **Accessibility tokens live in `AppTheme`** — pull from there, don't hardcode.
- **Supabase RLS migrations must add explicit GRANTs** to `anon`/`authenticated`.

Commands: `flutter analyze` · `flutter test` · `flutter run --dart-define-from-file=dart_defines.json`.
