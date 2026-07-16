# Compliance Checklist — COPPA / GDPR-K posture (M3 NFR-safety)

Status of the app's child-privacy posture as of M3, split into **what the code
already guarantees** (verifiable in this repo) and **what requires human/legal
action before a public release**. PRD §3's bullets: COPPA + GDPR-K compliance,
data minimization, no behavioral ads, kidSAFE-style posture.

## Data inventory (what the app actually collects/stores)

| Data | Where | PII? | Purpose | Retention |
|---|---|---|---|---|
| Anonymous auth UUID | Supabase Auth | No — random, no email/name/phone | Stable per-device learner id for RLS + sync | Until app data cleared |
| Per-item learning state (correct/incorrect counts, attempts, response ms, pronunciation score, SRS schedule) | drift (device) + `learner_item_states` (Supabase, RLS: own rows only) | No | Adaptive scheduling (PRD F3), parent dashboard | Until app data cleared |
| Local settings (screen-time limit, consent flag, no-reading mode) | drift only — never synced | No | Parent controls | Until app data cleared |
| Cached course content | drift only | No (public lesson content) | Offline play (M2) | Until app data cleared |
| Teacher email/password | Supabase Auth (teacher accounts only, created by the operator) | Yes — **adult** teacher accounts, not children | M0.5 curation gate | Operator-managed |

**Not collected at all:** child name, email, phone, photos, contacts, precise
location, advertising identifiers, free-text input from children (the child UI
has no text entry), device fingerprints.

## Code-level guarantees (verifiable in this repo)

- **No analytics / no ads SDKs.** `pubspec.yaml` contains no analytics,
  crash-reporting, or advertising dependency. Nothing behavioral leaves the
  device beyond the learning-state rows above.
- **Anonymous-by-default auth.** Children never create accounts or enter
  identity data; `signInAnonymously()` issues a random UUID
  (`core/supabase/app_supabase.dart`).
- **Speech audio never leaves our code.** The M2 speak activity uses the
  platform's on-device recognizer (`speech_to_text`); the app receives only
  the text transcript, stores only a numeric 0–1 score, and never records,
  stores, or uploads audio (see `core/speech/on_device_speech_service.dart`
  and the AndroidManifest/Info.plist purpose strings).
- **Parental consent gate before first play** (M1, `features/consent_gate/`):
  age-gate math check + guardian confirmation, persisted locally. This is the
  *stub* tier — see the human-action list for what full COPPA verifiable
  parental consent adds.
- **Least-privilege data access.** RLS restricts `learner_item_states` to the
  owning auth uid; content tables are read-only to clients; all content writes
  go through the Edge Function's server-side `service_role` (never shipped in
  the client). Teacher actions (approve/reject/edit) are role-checked
  server-side against `profiles.role`.
- **Secrets hygiene.** No secrets in the repo; client config via gitignored
  `dart_defines.json`; server secrets as Edge Function secrets only.
- **Data deletion path.** All child data is keyed to the anonymous UUID;
  clearing app data destroys the local store and orphans the remote rows,
  which contain nothing identifying. (A remote hard-delete endpoint is listed
  below as a release item.)

## Requires human / legal action before public release

These cannot be closed by code in this repo and are intentionally **open**:

1. **Verifiable parental consent (COPPA §312.5).** The M1 math-gate is a
   deterrent, not "verifiable consent." Public release needs a recognized
   method (credit-card check, signed form, ID match) — product/legal decision.
2. **Privacy policy** — written by counsel, published at a stable URL, linked
   from both app stores and the parent dashboard.
3. **App-store data-safety forms** (Google Play Data safety, Apple privacy
   labels) — filled to match the inventory above.
4. **kidSAFE / COPPA Safe Harbor certification** (if pursued) — third-party
   audit engagement.
5. **GDPR-K (Art. 8) age-of-consent mapping** for target EU markets and a
   remote delete/export endpoint ("right to erasure" — trivial given the
   anonymous keying, but must exist and be documented).
6. **DPA with Supabase** (processor agreement) + data-residency review for
   the chosen project region (`ap-southeast-1` for dev).

## Standing rules (every future change)

- New dependency → re-verify it embeds no analytics/ads/tracking.
- New table with child data → RLS to own-uid, add to the inventory above.
- Never add free-text input surfaces to the child UI without legal review
  (free text is where accidental PII collection starts).
