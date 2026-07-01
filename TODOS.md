# TODOS

Deferred items surfaced during reviews. Each entry has enough context that
someone picking it up later (including a future Claude Code session)
understands the motivation and where to start.

## Decide LLM provider/model for the M0.5 AI Lesson Generator

**What:** Pick and record which LLM provider (Anthropic, OpenAI, etc.) and
model the M0.5 Edge Function calls to generate lesson content.

**Why:** Currently unspecified anywhere in `docs/implementation-plan.md` or
the `/office-hours` design doc. Blocks the concrete secret-custody setup
(T2) and output-schema/validation work (T3) in the M0.5 Implementation
Tasks list, since schema-constrained generation (tool use / structured
output / JSON mode) differs by provider.

**Pros:** Small, cheap decision. Unblocks the Edge Function build the
moment it starts.

**Cons:** Deciding it now, before any M0.5 code exists, risks being
premature if requirements shift once the output schema is nailed down.

**Context:** Surfaced during `/plan-eng-review` of the M0.5 roadmap
revision (see `docs/implementation-plan.md`). Relevant only when M0.5
build actually starts — not blocking anything today.

**Depends on / blocked by:** Nothing blocks deciding this. It blocks
M0.5 Implementation Tasks T2 and T3 once M0.5 work begins.
