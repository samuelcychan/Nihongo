# TODOS

Deferred items surfaced during reviews. Each entry has enough context that
someone picking it up later (including a future Claude Code session)
understands the motivation and where to start.

## Revisit `validateLesson`'s glyph check for multi-codepoint emoji

**What:** `[...glyph].length > 4` in `supabase/functions/generate-lesson/index.ts`
rejects any glyph with more than ~4 code points, as a rough "is this a single
emoji" sanity check.

**Why:** Surfaced during real M0.5 verification — a "family members" generation
was rejected by this check. Family/multi-person emoji (ZWJ sequences) can
legitimately exceed 4 code points, so this may be a false rejection rather
than the model actually returning bad output. Not confirmed either way yet.

**Pros:** Cheap to investigate — log the actual rejected glyph next time this
fires, or add a family-members-topic test case.

**Cons:** Low priority; "family members" isn't a core topic and the rejection
fails safely (no bad content reached anyone).

**Context:** From `docs/implementation-tasks.md`'s "Real verification results"
table. Relevant only if family/multi-person topics come up again.

**Depends on / blocked by:** Nothing.
