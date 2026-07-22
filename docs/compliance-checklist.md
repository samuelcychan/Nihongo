# Compliance Checklist — COPPA / GDPR-K posture (M3 NFR-safety)

Status of the app's child-privacy posture as of M3, split into **what the code
already guarantees** (verifiable in this repo) and **what requires human/legal
action before a public release**. PRD §3's bullets: COPPA + GDPR-K compliance,
data minimization, no behavioral ads, kidSAFE-style posture.

## ⚠️ Change of posture: direct learner registration (post-M3)

The landing page (`features/landing/`) added **optional direct learner
registration** — the child's own email + password, upgrading their anonymous
session in place so progress carries over. This was an explicit product
decision (anonymous play remains available via "Continue without an
account"), but it materially changes the compliance picture below: earlier
versions of this document could truthfully say "no child PII collected
directly." **That is no longer true when a learner registers.** Registration
is gated behind the existing parental-consent gate (`features/consent_gate/`)
so it can't be reached without at least the M1 stub-tier confirmation first —
but per the original note further down, that gate is a deterrent, not
COPPA-compliant "verifiable parental consent." This raises the urgency of
that open item from "should do before public release" to "should not launch
learner registration publicly without it" — treat it as a blocker for this
feature specifically, not just the general release checklist.

## Data inventory (what the app actually collects/stores)

| Data | Where | PII? | Purpose | Retention |
|---|---|---|---|---|
| Anonymous auth UUID | Supabase Auth | No — random, no email/name/phone | Stable per-device learner id for RLS + sync | Until app data cleared |
| **Learner account email + password** (optional, if registered) | Supabase Auth (`auth.users`) | **Yes — from the child**, if they register | Cross-device progress persistence (landing page) | Account-lifetime; deletable via account deletion |
| Learner display name (optional) | `profiles.display_name` | Yes, if provided — a name, from the child | Shown wherever the account is referenced | Account-lifetime |
| Per-item learning state (correct/incorrect counts, attempts, response ms, pronunciation score, SRS schedule) | drift (device) + `learner_item_states` (Supabase, RLS: own rows only) | No | Adaptive scheduling (PRD F3), parent dashboard | Until app data cleared |
| Local settings (screen-time limit, consent flag, no-reading mode, landing-seen flag) | drift only — never synced | No | Parent controls / app state | Until app data cleared |
| Cached course content | drift only | No (public lesson content) | Offline play (M2) | Until app data cleared |
| Teacher email/password | Supabase Auth (teacher accounts only, created by the operator) | Yes — **adult** teacher accounts, not children | M0.5 curation gate | Operator-managed |

**Not collected at all:** child phone, photos, contacts, precise location,
advertising identifiers, free-text input beyond the landing page's own
name/email/password fields, device fingerprints. (Child *email* moved from
"not collected" to "collected" above — see the callout at the top of this
section.)

## Code-level guarantees (verifiable in this repo)

- **No analytics / no ads SDKs.** `pubspec.yaml` contains no analytics,
  crash-reporting, or advertising dependency. Nothing behavioral leaves the
  device beyond the learning-state rows above.
- **Anonymous-by-default auth, registration optional.** `signInAnonymously()`
  issues a random UUID by default (`core/supabase/app_supabase.dart`) and the
  app is fully playable without ever registering. **Correction from earlier
  versions of this doc:** it is no longer true that "children never create
  accounts" — the landing page's "Sign Up" path lets a learner register with
  a real email, gated behind the consent gate below. Anonymous play remains
  the path with zero identity collection.
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
- **Data deletion path (anonymous accounts).** All data is keyed to the
  anonymous UUID; clearing app data destroys the local store and orphans the
  remote rows, which contain nothing identifying.
  **Registered accounts are different:** the email/password/display-name live
  in `auth.users`/`profiles`, which are identifying and are *not* deleted by
  clearing local app data. There is currently no in-app "delete my account"
  action — a remote hard-delete endpoint (Edge Function, service_role) is
  listed below as a release item, and is now a real gap, not a theoretical
  one, once any learner has registered.

## Requires human / legal action before public release

These cannot be closed by code in this repo and are intentionally **open**:

1. **Verifiable parental consent (COPPA §312.5) — now urgent, not just
   "before public release."** The M1 math-gate is a deterrent, not
   "verifiable consent," and it sits in front of learner registration
   (`features/landing/`), which now collects a real child email. Do not
   publicly launch or promote the Sign Up path until this is resolved with a
   recognized method (credit-card check, signed form, ID match) —
   product/legal decision. Anonymous play is unaffected and can ship as-is.
2. **Privacy policy** — written by counsel, published at a stable URL, linked
   from both app stores and the parent dashboard.
3. **App-store data-safety forms** (Google Play Data safety, Apple privacy
   labels) — filled to match the inventory above.
4. **kidSAFE / COPPA Safe Harbor certification** (if pursued) — third-party
   audit engagement.
5. **GDPR-K (Art. 8) age-of-consent mapping** for target EU markets and a
   remote delete/export endpoint ("right to erasure" — trivial for anonymous
   accounts given the UUID keying, but registered accounts now hold real
   identifying data with no delete path yet; must exist and be documented).
6. **DPA with Supabase** (processor agreement) + data-residency review for
   the chosen project region (`ap-southeast-1` for dev).

## Standing rules (every future change)

- New dependency → re-verify it embeds no analytics/ads/tracking.
- New table with child data → RLS to own-uid, add to the inventory above.
- Never add free-text input surfaces to the child UI without legal review
  (free text is where accidental PII collection starts).
- Any change to `features/landing/` (registration/login) → re-read the
  callout at the top of this document before shipping; that surface is the
  one place in the app that collects real identity data from a child.
