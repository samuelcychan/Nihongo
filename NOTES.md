# Sprout theme → Flutter drop-in

Reskins the existing `kids_lang` app to the **Sprout** direction (warm cream,
leafy green, Fredoka + Nunito, chunky tactile shadows) without touching any game
logic, providers, routing, or persistence.

## 1. Add the font dependency

The theme loads Fredoka + Nunito via Google Fonts. Add to `pubspec.yaml`:

```yaml
dependencies:
  google_fonts: ^6.2.1   # or latest
```

then `flutter pub get`.

> Prefer bundling? Download Fredoka + Nunito TTFs, declare them under
> `flutter: fonts:` in `pubspec.yaml`, and swap the `GoogleFonts.fredoka(...)` /
> `GoogleFonts.nunito(...)` calls in `app_theme.dart` for
> `TextStyle(fontFamily: 'Fredoka' / 'Nunito', ...)`.

## 2. Copy the files (same paths as the original)

| File | Replaces / adds |
|------|------|
| `lib/app/theme/app_theme.dart` | replaces the theme — full Sprout palette + helpers (`AppTheme.chunky`, `AppTheme.cardDecoration`, `AppTheme.softShadow`) |
| `lib/app/router/app_router.dart` | replaces the router — adds `/map`, `/complete`, `/parents` |
| `lib/features/learner_home/learner_home_page.dart` | replaces Home (now links to Map / Stars / Parents) |
| `lib/features/activity_match/activity_match_page.dart` | replaces Match |
| `lib/features/lesson_map/lesson_map_page.dart` | **new** — Lesson map (`/map`) |
| `lib/features/round_complete/round_complete_page.dart` | **new** — Round-complete celebration (`/complete`) |
| `lib/features/parent_dashboard/parent_dashboard_page.dart` | **new** — Parent dashboard (`/parents`) |
| `supabase/migrations/0003_seed_japanese.sql` | **new** — converts the seed course to Japanese |

`AppTheme.light()` is still wired through `app.dart`, so the new look applies
app-wide once the theme file is replaced.

### The new screens at a glance
- **Lesson map** — winding dashed path of nodes (done / current / locked); the
  current "Animals" node deep-links into `/play`. Node list is local for now.
- **Round complete** — celebration with animated stars, stars-earned chip, and a
  sticker-reward card. Takes the outcome via constructor params (defaults make
  it previewable); wire real stars from attempts/accuracy in `ActivityMatchPage`.
- **Parent dashboard** — `Words mastered` is read from the live `progressProvider`
  stream; time / accuracy / streak and the weekly chart are placeholders until
  those aggregates exist.

## 3. Apply the Japanese content

Run the new migration against your Supabase project (or paste it into the SQL
editor). It flips the seed course `target_language` to `ja` and replaces the six
items with `ねこ / いぬ / とり / さかな / うし / あひる` (same emoji pictures).
Set the TTS engine locale to `ja-JP` in `AudioService` so the words are
pronounced correctly.

## 4. What was preserved vs. changed

**Unchanged (logic):** all Riverpod providers, `MatchRoundBuilder`, the
`_Status` state machine, `recordResult` persistence, the offline sync listener,
widget `Key`s used by tests (`progress_badge`, `option_*`, `feedback_correct`,
`feedback_wrong`, `activity_done`), and the accessibility floor
(`minTapTarget = 96`, captions, icon-backed feedback).

**Changed (presentation only):**
- Home: AppBar dropped in favour of an in-body greeting (`おはよう、Mia！`) +
  streak chip + course card with progress bar + chunky Play button.
- Match: segmented progress dots, round green speaker button, pill feedback
  banners, white tiles with 4px state border + hard bottom shadow.
- Course label reads `EN → JP`; correct-feedback praise is Japanese
  (`せいかい！`, done screen `すごい！`).

## 5. Still to do (not in this drop)

- **Parent metrics** — time-on-task, accuracy, day-streak and the weekly chart
  are placeholders; back them with real session aggregates.
- **Lesson map data** — replace the local node list with the real
  units → lessons hierarchy and per-lesson mastery.
- The streak count on Home is hard-coded (`days: 3`); wire it to real data.
- Hand-drawn art (reward stickers, hero illustrations) are emoji/placeholders —
  swap for real assets when ready.
- Optional: a `ShellRoute` with a persistent bottom nav (Home / Map / Stars /
  Parents) to match the mock's tab bar.
