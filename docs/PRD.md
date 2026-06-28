# Product Requirements — Kids Language-Learning App

**Platform:** Flutter (iOS & Android)  ·  **Audience:** young learners  ·  **Status:** Draft v0.1

> **Note (added when versioning into the repo):** this is the original draft v0.1, reproduced
> verbatim below. The three "to confirm" items have since been resolved for the current build:
> **age band = 6–10**, **target language = Japanese** (data-driven), **use context = mixed home +
> classroom**. See [design.md](design.md) for the decisions and scope built against these.

## 1. Overview
A cross-platform, play-first language-learning app for children, built in Flutter. Learning happens through interactive multimedia activities with adaptive difficulty, while teachers author and maintain the course content.

> **To confirm:** primary age band `____`, target languages `____`, primary use context (home / classroom). These materially affect scope.

## 2. Core Features — *Must-have*

### F1 · Rich Interactive Multimedia Content
Lessons are media-dense and tactile to hold young attention.
- Support images, audio, video, and vector animations (e.g. Rive/Lottie) per activity.
- Interaction types: tap, drag-and-drop, trace/draw, match, sequence.
- Immediate audio-visual feedback (sound + animation) on every action.
- Large, glanceable tap targets; minimal on-screen text for pre-readers.

### F2 · Multimodal Input & Output
The child engages via the easiest available channel — no reading or typing required.
- **Input:** touch, drag, voice (speech / pronunciation capture), optional drawing.
- **Output:** native-speaker audio + TTS, visuals, toggleable captions, haptics.
- "No-reading" mode for pre-literate users — voice prompts replace text instructions.
- On-device speech processing preferred, given the sensitivity of children's voice data.

### F3 · Adaptive Learner Memory & Guided Difficulty
The app remembers each child's history and keeps challenge in the right zone.
- Persist per-item results: correct/incorrect, attempts, response time, pronunciation score.
- Spaced-repetition scheduling to resurface weak items for review.
- Auto-adjust the difficulty of the next item so content stays challenging but not frustrating.
- Evaluate all responses (including speech) and surface progress to learner and parent.
- Learner state syncs across devices and sessions.

### F4 · Teacher Authoring System
Teachers create and edit courses without engineering help.
- Authoring interface (web or in-app teacher mode) with role-based access (teacher / learner / parent).
- Content hierarchy: **Course → Unit → Lesson → Activity**.
- Create/edit items, upload media, configure mini-games, and tag difficulty (feeds F3).
- Preview, version, and publish workflow before content goes live.

## 3. Non-Functional / Table-Stakes Requirements
- **Safety & privacy:** COPPA + GDPR-K compliant, parental-consent gate, no behavioral ads, minimal data collection (kidSAFE-style posture).
- **Offline:** download lessons and media for offline play; sync progress on reconnect.
- **Parent/guardian dashboard:** progress reports and screen-time controls.
- **Accessibility:** pre-reader support, large targets, colorblind-safe palette, audio cues.
- **Performance:** smooth 60 fps animations, fast load, media caching.
- **Cross-platform parity:** equivalent experience on iOS and Android.

## 4. Out of Scope (v1)
Live human tutoring, social/multiplayer features, and AR — revisit post-launch.
