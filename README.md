# Nihongo — Kids' Japanese Learning App

A play-first, cross-platform **Flutter** app that teaches young children (ages 6–10)
vocabulary through interactive tap-to-match mini-games — with on-device audio, immediate
audio-visual feedback, adaptive spaced repetition, and offline-first progress that syncs to
**Supabase**. Current content teaches **Japanese** (the target language is data-driven).

> Status: a working vertical slice (one "Animals" lesson) with a "Sprout" visual design and
> home / lesson-map / activity / round-complete / progress / parent-dashboard screens.

## Features
- 🎮 **Tap-to-match** activity with large emoji targets and instant feedback (せいかい！ / try-again)
- 🔊 **On-device TTS** speaks each word in the course's language (no audio assets shipped)
- 🧠 **Spaced repetition** (SM-2-lite) schedules reviews and adapts item order
- 📴 **Offline-first**: results persist locally and sync to Supabase when back online
- ⭐ Progress ("My Stars"), round-complete celebration, and a parent dashboard
- ♿ Accessibility-minded: large tap targets, readable type, colorblind-safe feedback

## Tech stack
Flutter · Riverpod 3 · go_router · supabase_flutter · drift (offline SQLite) · flutter_tts ·
flutter_animate · google_fonts. Plain Dart models; build_runner is used for drift only.

## Getting started
**Prerequisites:** Flutter (stable), an Android emulator or device. For the backend, a
Supabase project with anonymous sign-ins enabled (the app runs without it in offline mode).

1. Install deps:
   ```bash
   flutter pub get
   dart run build_runner build --delete-conflicting-outputs   # generates drift code
   ```
2. Configure Supabase (keys are **not** committed). Copy the example and fill it in:
   ```bash
   cp dart_defines.example.json dart_defines.json   # then edit with your URL + anon key
   ```
3. Run:
   ```bash
   flutter run -d <device> --dart-define-from-file=dart_defines.json
   ```
   (Using Claude Code? just run `/run` — it builds, installs, and launches on the emulator.)

**Test & analyze:**
```bash
flutter analyze
flutter test
```

## Project layout
`lib/app` (theme, router, providers) · `lib/core` (audio, db, srs, supabase, sync) ·
`lib/data` (repositories) · `lib/domain/models` · `lib/features/*` (screens) ·
`supabase/migrations` (schema + RLS + seed). Full map in [AGENTS.md](AGENTS.md).

## Documentation
- [docs/PRD.md](docs/PRD.md) — product requirements (the *what*)
- [docs/design.md](docs/design.md) — architecture, scope, decisions (the *why*)
- [AGENTS.md](AGENTS.md) — conventions & commands for contributors and AI agents (the *how*)

## License
TBD.
