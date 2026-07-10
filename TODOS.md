# TODOS

Deferred items surfaced during reviews. Each entry has enough context that
someone picking it up later (including a future Claude Code session)
understands the motivation and where to start.

_No open items right now — the glyph-validation TODO was resolved: the
Edge Function now checks `Intl.Segmenter(..., { granularity: 'grapheme' })`-based
grapheme-cluster count instead of raw code-point length, so multi-codepoint
emoji (e.g. family ZWJ sequences) correctly count as a single glyph. See
`supabase/functions/generate-lesson/index.ts`._
