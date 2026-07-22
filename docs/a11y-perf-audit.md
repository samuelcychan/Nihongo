# Accessibility & Performance Audit (M3 NFR-a11y / NFR-perf)

Code-level audit of every child-facing surface, plus what genuinely needs
real hardware. Fixes found by this audit were applied in the same change.

## Accessibility audit

Bar (from PRD §3 + AppTheme's contract): color never carries meaning alone,
audio cues on every feedback path, ≥48dp tap targets, screen-reader labels on
interactive elements, playable pre-reader path.

| Surface | Color+icon/motion | Audio cue | Tap target ≥48dp | Semantics | Notes |
|---|---|---|---|---|---|
| Match activity | ✅ banner icon + tile border + shake/scale | ✅ word, Great job/Try again | ✅ 96dp tiles | ✅ | no-reading mode hides captions (M2) |
| Drag & drop | ✅ check/close icons on targets | ✅ | ✅ 57–67dp | ✅ **(fixed: added labels to draggables + drop targets)** | word labels are intrinsic to the game |
| Sequence | ✅ shake + border | ✅ | ✅ 81dp | ✅ | numbered slots also encode position |
| Speak | ✅ banner icons, listening color+pulse | ✅ | ✅ 110dp mic | ✅ | fully playable with zero reading (no-reading hides prompt) |
| Consent gate / parent surfaces | adult-facing; standard Material a11y | n/a | ✅ | ✅ | not a child surface |

- **Colorblind safety:** every correct/incorrect state pairs color with an
  icon (check/close/refresh) and/or motion (shake/scale) — verified per
  surface above; `AppTheme` centralizes the palette.
- **No-reading mode (M2)** covers the pre-reader path: match + speak are
  fully playable with no on-screen text; drag-drop/sequence intrinsically
  show word labels (they teach word recognition) and are simply not the
  activities to assign a pre-reader.

## Performance audit

- **Cold start:** `main()` does exactly two things before the first frame:
  `Supabase.initialize` (local) and, on first run only, an anonymous sign-in.
  **Fixed in this audit:** the sign-in is now bounded (6s timeout, boots
  anyway, auth-reactive learner id picks the session up when it lands) — a
  slow first-run network can no longer hold the splash for 10–15s.
  Subsequent launches restore the session locally and skip it entirely.
- **Media:** no bundled binary assets; images are network-loaded with emoji
  fallback; lesson content is cached in drift after first fetch (M2), so
  repeat plays make zero content requests.
- **Animations:** feedback animations are single-widget `flutter_animate`
  micro-effects (shake/scale ≤400ms), no per-frame Dart work; lists are
  bounded (≤10 items per lesson) so no virtualization concerns.
- **Build hygiene:** `flutter analyze` is CI-gated; const constructors used
  throughout the hot activity widgets.

## Needs real low-end hardware (cannot be closed in this repo)

1. **60fps verification on a low-end device** — profile-mode run
   (`flutter run --profile`) on a ~2GB-RAM Android device, watching the
   performance overlay during activity feedback animations.
2. **Cold-start stopwatch on target hardware** — the audit above fixes the
   known network-bound stall; absolute numbers need a device.
3. **TalkBack / VoiceOver walkthrough** — Semantics labels exist on all
   interactive elements (table above); a real screen-reader pass on-device
   should confirm focus order feels right to a human.
