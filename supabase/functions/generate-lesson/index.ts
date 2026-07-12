// M0.5 AI Lesson Generator (see docs/implementation-plan.md and
// docs/implementation-tasks.md T2-T4).
//
// Given a topic, generates a Course->Unit->Lesson->Activity->Item lesson using
// OpenAI-compatible Structured Outputs, validates it server-side, runs a
// second-pass translation-correctness check, and writes it into the fixed
// AI-generated draft course (published = false) via the admin (service_role)
// client so it stays invisible to learners until a human approves a generated
// unit (moving it into the published seed course).
//
// LLM calls go through OpenRouter (https://openrouter.ai), not OpenAI
// directly, to lower cost -- routed to openai/gpt-4o-mini specifically
// because OpenRouter forwards that model straight to OpenAI, so the strict
// json_schema structured-output guarantee T3/T4 rely on is unaffected; a
// non-OpenAI OpenRouter model would need looser response_format handling.
//
// Secrets required (function secrets only -- never in dart_defines.json or
// client code): OPENROUTER_API_KEY. The Supabase service-role client is
// provided by the runtime as ctx.supabaseAdmin -- no separate key to manage.

import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

const OPENROUTER_API_URL = "https://openrouter.ai/api/v1/chat/completions";
const LLM_MODEL = "openai/gpt-4o-mini";

/** Shared OpenRouter call -- both callOpenAI and verifyTranslations hit the
 * same OpenAI-compatible endpoint with a structured-output schema. */
async function callLLM(
  messages: { role: string; content: string }[],
  schemaName: string,
  // deno-lint-ignore no-explicit-any
  schema: any,
): Promise<string> {
  const apiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) {
    throw new GenerationError("OPENROUTER_API_KEY not configured", 500);
  }
  const res = await fetch(OPENROUTER_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      // Optional but recommended by OpenRouter for attribution/rate-limit purposes.
      "HTTP-Referer": "https://github.com/samuelcychan/Nihongo",
      "X-Title": "Nihongo M0.5 AI Lesson Generator",
    },
    body: JSON.stringify({
      model: LLM_MODEL,
      messages,
      response_format: {
        type: "json_schema",
        json_schema: { name: schemaName, strict: true, schema },
      },
    }),
  });

  if (!res.ok) {
    // Explicit, non-silent failure -- surfaced to the client as an error,
    // never dropped (see docs/implementation-plan.md's failure-modes table).
    const body = await res.text();
    throw new GenerationError(`OpenRouter request failed: ${res.status} ${body}`);
  }
  const data = await res.json();
  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new GenerationError("OpenRouter returned no content");
  }
  return content as string;
}

// Course created by migration 0004_ai_generated_course.sql. New lessons are
// always written here first -- it never receives writes that skip review.
const DRAFT_COURSE_ID = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa";

// The existing published seed course (0002_seed.sql) that approved lessons
// move into. "Approve" is a lightweight action, not full M3 curation tooling
// (edit-before-publish, rejection reasons, etc. stay M3 scope) -- it's just
// enough for T5's preview -> approve flow to be real rather than a stub.
const PUBLISHED_COURSE_ID = "11111111-1111-1111-1111-111111111111";

const MIN_ITEMS = 6;
const MAX_ITEMS = 10;
const GLYPH_SEGMENTER = new Intl.Segmenter(undefined, { granularity: "grapheme" });

// The activity types the Flutter client actually renders a page for (see
// app_router.dart's '/play' dispatch) -- 'trace' and 'speak' are allowed by
// the DB check constraint for future use but have no client UI yet, so the
// generator doesn't offer them.
const SUPPORTED_ACTIVITY_TYPES = ["match", "drag_drop", "sequence"] as const;
type ActivityType = (typeof SUPPORTED_ACTIVITY_TYPES)[number];

function isSupportedActivityType(value: unknown): value is ActivityType {
  return (
    typeof value === "string" &&
    (SUPPORTED_ACTIVITY_TYPES as readonly string[]).includes(value)
  );
}

interface GeneratedItem {
  self_check: string; // scratch field -- see ITEM_SCHEMA; never persisted
  prompt_text: string;
  answer: string;
  glyph: string;
  difficulty: number; // 1-5
  category: string; // used for same-category distractor plausibility
}

interface GeneratedLesson {
  lesson_title: string;
  items: GeneratedItem[];
}

const ITEM_SCHEMA = {
  type: "object",
  properties: {
    lesson_title: { type: "string" },
    items: {
      type: "array",
      minItems: MIN_ITEMS,
      maxItems: MAX_ITEMS,
      items: {
        type: "object",
        properties: {
          // Declared first so strict-mode's autoregressive generation writes
          // this before committing to prompt_text -- a self-critique pass
          // baked into the schema itself, not a separate call. Never
          // persisted to the DB; stripped before writing (see below).
          self_check: {
            type: "string",
            description:
              "Before answering: is prompt_text the single most common, " +
              "everyday Japanese word a native child would actually use for " +
              "this concept -- NOT a scientific/taxonomic name, rare " +
              "synonym, or formal/literary term? Briefly justify the word " +
              "choice here first.",
          },
          prompt_text: { type: "string", description: "The Japanese word/phrase." },
          answer: { type: "string", description: "Must equal prompt_text." },
          glyph: { type: "string", description: "A single emoji representing the word." },
          difficulty: { type: "integer", minimum: 1, maximum: 5 },
          category: { type: "string", description: "Broad category, e.g. 'animal', 'food'." },
        },
        required: ["self_check", "prompt_text", "answer", "glyph", "difficulty", "category"],
        additionalProperties: false,
      },
    },
  },
  required: ["lesson_title", "items"],
  additionalProperties: false,
} as const;

class GenerationError extends Error {
  constructor(
    message: string,
    public status = 502,
  ) {
    super(message);
  }
}

async function callOpenAI(topic: string): Promise<GeneratedLesson> {
  const content = await callLLM(
    [
      {
        role: "system",
        content:
          "You write vocabulary lessons for a kids' Japanese-learning app " +
          "(ages 6-10). For the given topic, produce between " +
          `${MIN_ITEMS} and ${MAX_ITEMS} Japanese words a beginner child ` +
          "would learn. Each item needs: the Japanese word (hiragana " +
          "preferred over kanji for early readers), a single representative " +
          "emoji, a difficulty 1-5 (1=very common/simple, 5=harder), and a " +
          "broad category so a UI can pick plausible wrong-answer options " +
          "from the same category. Keep language age-appropriate and " +
          "unambiguous -- this is the only content a young child sees. " +
          "Always prefer the single most common, everyday word for a " +
          "concept; never reach for a scientific/taxonomic name, a rare or " +
          "obscure synonym, or formal/literary register just because it is " +
          "technically correct -- use the self_check field on each item to " +
          "verify this before answering.",
      },
      { role: "user", content: `Topic: ${topic}` },
    ],
    "lesson",
    ITEM_SCHEMA,
  );
  try {
    return JSON.parse(content) as GeneratedLesson;
  } catch (e) {
    throw new GenerationError(`LLM returned invalid JSON: ${e}`, 502);
  }
}

const VERIFICATION_SCHEMA = {
  type: "object",
  properties: {
    results: {
      type: "array",
      items: {
        type: "object",
        properties: {
          index: { type: "integer" },
          ok: { type: "boolean" },
          issue: {
            type: ["string", "null"],
            description: "Why this item is wrong, ambiguous, or inappropriate. Null if ok.",
          },
          replacement_word: {
            type: ["string", "null"],
            description:
              "If ok is false and you are confident of a correct, common, " +
              "unambiguous Japanese word for this category (hiragana " +
              "preferred), provide it here. Null if ok is true, or if you " +
              "aren't confident of any safe replacement -- in that case the " +
              "item is simply dropped rather than risking another wrong word.",
          },
          replacement_glyph: {
            type: ["string", "null"],
            description:
              "A single emoji matching replacement_word. Null unless " +
              "replacement_word is provided.",
          },
        },
        required: ["index", "ok", "issue", "replacement_word", "replacement_glyph"],
        additionalProperties: false,
      },
    },
  },
  required: ["results"],
  additionalProperties: false,
} as const;

interface VerificationVerdict {
  index: number;
  ok: boolean;
  issue: string | null;
  replacement_word: string | null;
  replacement_glyph: string | null;
}

/**
 * T4 -- translation-correctness mitigation (second-pass verification).
 *
 * Schema validation alone (T3) only proves the JSON is well-formed; it does
 * NOT catch a wrong-but-well-formed translation, the single worst failure
 * mode for this feature (a kid confidently learns the wrong word). This asks
 * a second, independent LLM call to fact-check each item.
 *
 * Auto-repair, not all-or-nothing: earlier, ANY flagged item failed the
 * whole batch, discarding an otherwise-good 8-9 item lesson over one bad
 * word. Now each flagged item is either replaced in place (verifier is
 * confident of a fix) or dropped (it isn't) -- the independent check is
 * preserved, but a single bad word no longer costs the whole generation.
 * validateLesson() still runs afterward as the final gate (e.g. too many
 * items dropped to meet MIN_ITEMS).
 */
async function verifyTranslations(
  lesson: GeneratedLesson,
): Promise<{ lesson: GeneratedLesson; notes: string[] }> {
  const content = await callLLM(
    [
      {
        role: "system",
        content:
          "You are a strict Japanese-language fact-checker. Given a " +
          "numbered list of (index, word, category) items, verify each " +
          "word is a correct, common, and unambiguous Japanese word for " +
          "that category -- appropriate for teaching a young " +
          "English-speaking child (reject scientific/taxonomic names, " +
          "rare synonyms, and formal/literary register even if technically " +
          "correct). For every item, set ok:true if it's fine. If " +
          "ok:false, explain in issue, and if you're confident of a " +
          "correct common word for the concept, provide it as " +
          "replacement_word plus a matching replacement_glyph -- otherwise " +
          "leave both null.",
      },
      {
        role: "user",
        content: JSON.stringify(
          lesson.items.map((item, index) => ({
            index,
            word: item.prompt_text,
            category: item.category,
          })),
        ),
      },
    ],
    "verification",
    VERIFICATION_SCHEMA,
  );
  let parsed: { results: VerificationVerdict[] };
  try {
    parsed = JSON.parse(content) as { results: VerificationVerdict[] };
  } catch (e) {
    throw new GenerationError(`verification returned invalid JSON: ${e}`, 502);
  }

  const expectedCount = lesson.items.length;
  const seenVerdicts = new Set<number>();
  for (const r of parsed.results) {
    if (!Number.isInteger(r.index) || r.index < 0 || r.index >= expectedCount) {
      throw new GenerationError(`verification returned out-of-range index: ${r.index}`, 502);
    }
    if (seenVerdicts.has(r.index)) {
      throw new GenerationError(`verification returned duplicate index: ${r.index}`, 502);
    }
    seenVerdicts.add(r.index);
  }
  if (seenVerdicts.size !== expectedCount) {
    throw new GenerationError(
      `verification returned ${seenVerdicts.size}/${expectedCount} results`,
      502,
    );
  }

  const verdictByIndex = new Map(parsed.results.map((r) => [r.index, r]));
  // Seed with answers being kept as-is, so a replacement that would collide
  // with an unflagged item (or with another item's replacement) is treated
  // as unfixable rather than silently introducing a duplicate answer --
  // validateLesson() would reject that anyway, but dropping it here means
  // one bad replacement doesn't waste the whole lesson.
  const usedAnswers = new Set(
    lesson.items
      .filter((_, i) => {
        const v = verdictByIndex.get(i);
        return !v || v.ok;
      })
      .map((item) => item.answer),
  );
  const repaired: GeneratedItem[] = [];
  const notes: string[] = [];
  for (const [i, item] of lesson.items.entries()) {
    const verdict = verdictByIndex.get(i);
    if (!verdict || verdict.ok) {
      repaired.push(item);
      continue;
    }
    const replacement = verdict.replacement_word?.trim();
    const replacementGlyph = verdict.replacement_glyph?.trim();
    const replacementGlyphCount = replacementGlyph
      ? Array.from(GLYPH_SEGMENTER.segment(replacementGlyph)).length
      : 0;

    if (
      replacement &&
      replacementGlyph &&
      replacementGlyphCount === 1 &&
      !usedAnswers.has(replacement)
    ) {
      usedAnswers.add(replacement);
      notes.push(
        `item ${i}: replaced "${item.prompt_text}" with "${replacement}"` +
          (verdict.issue ? ` (${verdict.issue})` : ""),
      );
      repaired.push({
        ...item,
        prompt_text: replacement,
        answer: replacement,
        glyph: replacementGlyph,
      });
    } else {
      const reason = replacement
        ? !replacementGlyph
          ? "replacement_glyph missing"
          : replacementGlyphCount !== 1
            ? "replacement_glyph is not a single emoji"
            : `replacement "${replacement}" duplicates another item`
        : verdict.issue ?? "flagged";
      notes.push(`item ${i}: dropped "${item.prompt_text}" (${reason})`);
    }
  }
  return { lesson: { ...lesson, items: repaired }, notes };
}

/** T3 -- server-side validation beyond OpenAI's own strict-mode guarantee:
 * DB-level constraints, item count, and duplicate-answer detection. */
function validateLesson(lesson: GeneratedLesson): string[] {
  const errors: string[] = [];
  if (!lesson.lesson_title?.trim()) errors.push("lesson_title is empty");
  if (lesson.items.length < MIN_ITEMS) {
    errors.push(`only ${lesson.items.length} items, need >= ${MIN_ITEMS}`);
  }
  if (lesson.items.length > MAX_ITEMS) {
    errors.push(`got ${lesson.items.length} items, need <= ${MAX_ITEMS}`);
  }
  const seenAnswers = new Set<string>();
  for (const [i, item] of lesson.items.entries()) {
    if (!item.prompt_text?.trim()) errors.push(`item ${i}: prompt_text is empty`);
    if (!item.answer?.trim()) errors.push(`item ${i}: answer is empty`);
    if (item.prompt_text !== item.answer) {
      errors.push(`item ${i}: answer must equal prompt_text (schema requirement)`);
    }
    const glyph = item.glyph?.trim();
    const graphemeCount = glyph
      ? Array.from(GLYPH_SEGMENTER.segment(glyph)).length
      : 0;
    if (graphemeCount !== 1) {
      errors.push(`item ${i}: glyph is missing or not a single emoji`);
    }
    if (!Number.isInteger(item.difficulty) || item.difficulty < 1 || item.difficulty > 5) {
      // matches the DB check constraint in 0001_init.sql
      errors.push(`item ${i}: difficulty ${item.difficulty} outside 1-5`);
    }
    if (seenAnswers.has(item.answer)) {
      errors.push(`item ${i}: duplicate answer "${item.answer}"`);
    }
    seenAnswers.add(item.answer);
  }
  // Same-category distractor plausibility: MatchRoundBuilder draws distractors
  // from the whole item pool, so if every item is a different category the
  // wrong options are trivially obvious. Require at least MIN_ITEMS/2 items
  // to share a category with at least one other item.
  const categoryCounts = new Map<string, number>();
  for (const item of lesson.items) {
    categoryCounts.set(item.category, (categoryCounts.get(item.category) ?? 0) + 1);
  }
  const itemsWithPeers = lesson.items.filter(
    (i) => (categoryCounts.get(i.category) ?? 0) > 1,
  ).length;
  if (itemsWithPeers < Math.floor(lesson.items.length / 2)) {
    errors.push(
      "too few same-category item pairs -- distractors would be trivially obvious",
    );
  }
  return errors;
}

/** Approve: move a draft unit (and everything under it) into the published
 * course. Reject: delete it. Both are a single statement -- FK cascades
 * (units->lessons->activities->items, see 0001_init.sql) handle the rest.
 * `admin` is ctx.supabaseAdmin (service_role client, bypasses RLS) -- typed
 * loosely here since @supabase/server doesn't export its client type. */
// deno-lint-ignore no-explicit-any
async function handleReview(
  admin: any,
  action: "approve" | "reject",
  unitId: string,
): Promise<Response> {
  if (action === "approve") {
    const { data, error } = await admin
      .from("units")
      .update({ course_id: PUBLISHED_COURSE_ID })
      .eq("id", unitId)
      .eq("course_id", DRAFT_COURSE_ID) // only ever move OUT of the draft course
      .select("id");
    if (error) {
      return Response.json({ error: `approve failed: ${error.message}` }, { status: 502 });
    }
    if (!data || data.length === 0) {
      return Response.json(
        { error: "approve failed: unit not found (or not in draft course)" },
        { status: 404 },
      );
    }
    return Response.json({ unit_id: unitId, status: "approved", course_id: PUBLISHED_COURSE_ID });
  }
  const { data, error } = await admin
    .from("units")
    .delete()
    .eq("id", unitId)
    .eq("course_id", DRAFT_COURSE_ID) // never allow deleting outside the draft course
    .select("id");
  if (error) {
    return Response.json({ error: `reject failed: ${error.message}` }, { status: 502 });
  }
  if (!data || data.length === 0) {
    return Response.json(
      { error: "reject failed: unit not found (or not in draft course)" },
      { status: 404 },
    );
  }
  return Response.json({ unit_id: unitId, status: "rejected" });
}

export default {
  fetch: withSupabase({ auth: ["user", "publishable"] }, async (req, ctx) => {
    let body: { action?: string; topic?: string; unit_id?: string; type?: string };
    try {
      body = await req.json();
    } catch {
      return Response.json({ error: "invalid JSON body" }, { status: 400 });
    }

    const action = body.action ?? "generate";
    if (action === "approve" || action === "reject") {
      if (typeof body.unit_id !== "string" || !body.unit_id.trim()) {
        return Response.json({ error: "unit_id (non-empty string) is required" }, {
          status: 400,
        });
      }
      // Authorization: only users with the teacher role may approve or reject.
      // Any other user (including anonymous learners) is forbidden.
      if (ctx.authMode !== "user" || !ctx.userClaims?.id) {
        return Response.json(
          { error: "forbidden: a teacher account is required to approve or reject" },
          { status: 403 },
        );
      }
      const { data: profile } = await ctx.supabaseAdmin
        .from("profiles")
        .select("role")
        .eq("id", ctx.userClaims.id)
        .single();
      if (!profile || profile.role !== "teacher") {
        return Response.json(
          { error: "forbidden: teacher role required to approve or reject" },
          { status: 403 },
        );
      }
      return handleReview(ctx.supabaseAdmin, action, body.unit_id);
    }

    const topic = body.topic;
    if (typeof topic !== "string" || !topic.trim()) {
      return Response.json({ error: "topic (non-empty string) is required" }, { status: 400 });
    }
    if (body.type !== undefined && !isSupportedActivityType(body.type)) {
      return Response.json(
        { error: `type must be one of ${SUPPORTED_ACTIVITY_TYPES.join(", ")}` },
        { status: 400 },
      );
    }
    const activityType: ActivityType = body.type === undefined ? "match" : body.type;

    let lesson: GeneratedLesson;
    try {
      lesson = await callOpenAI(topic);
    } catch (e) {
      const err = e as GenerationError;
      // Explicit, visible error -- never a silent drop (failure-modes table
      // in docs/implementation-plan.md).
      return Response.json({ error: `generation failed: ${err.message}` }, {
        status: err.status ?? 502,
      });
    }

    let verificationNotes: string[];
    try {
      const verified = await verifyTranslations(lesson);
      lesson = verified.lesson;
      verificationNotes = verified.notes;
    } catch (e) {
      const err = e as Error;
      return Response.json(
        { error: `translation verification failed: ${err.message}` },
        { status: 502 },
      );
    }

    // Runs AFTER verification/repair, not before -- validates the lesson
    // that will actually be written (post-replace/drop), so e.g. too many
    // items dropped to meet MIN_ITEMS is still caught here.
    const validationErrors = validateLesson(lesson);
    if (validationErrors.length > 0) {
      return Response.json(
        {
          error: "generated lesson failed validation after translation-correctness repair",
          details: validationErrors,
          corrections: verificationNotes,
        },
        { status: 422 },
      );
    }

    // Write via the admin client (service_role, bypasses RLS) -- this is the
    // only path that can write to content tables; anon/authenticated only
    // ever get `select` (see 0001_init.sql). The parent course stays
    // published = false, so nothing here is visible to a learner yet.
    const admin = ctx.supabaseAdmin;
    const { data: unit, error: unitError } = await admin
      .from("units")
      .insert({ course_id: DRAFT_COURSE_ID, title: lesson.lesson_title, position: 0 })
      .select("id")
      .single();
    if (unitError) {
      return Response.json({ error: `db write failed (unit): ${unitError.message}` }, {
        status: 502,
      });
    }

    const { data: lessonRow, error: lessonError } = await admin
      .from("lessons")
      .insert({ unit_id: unit.id, title: lesson.lesson_title, position: 0 })
      .select("id")
      .single();
    if (lessonError) {
      return Response.json({ error: `db write failed (lesson): ${lessonError.message}` }, {
        status: 502,
      });
    }

    const { data: activity, error: activityError } = await admin
      .from("activities")
      .insert({
        lesson_id: lessonRow.id,
        type: activityType,
        title: lesson.lesson_title,
        position: 0,
        // drag_drop and sequence read straight from items, no extra config
        // (see DragDropActivityPage/SequenceActivityPage) -- optionCount/speak
        // are match-only (ActivityMatchPage).
        config: activityType === "match" ? { optionCount: 4, speak: true } : {},
      })
      .select("id")
      .single();
    if (activityError) {
      return Response.json({ error: `db write failed (activity): ${activityError.message}` }, {
        status: 502,
      });
    }

    const { error: itemsError } = await admin.from("items").insert(
      lesson.items.map((item, i) => ({
        activity_id: activity.id,
        prompt_text: item.prompt_text,
        answer: item.answer,
        glyph: item.glyph,
        difficulty: item.difficulty,
        position: i,
      })),
    );
    if (itemsError) {
      return Response.json({ error: `db write failed (items): ${itemsError.message}` }, {
        status: 502,
      });
    }

    return Response.json({
      lesson_id: lessonRow.id,
      unit_id: unit.id,
      activity_id: activity.id,
      activity_type: activityType,
      lesson_title: lesson.lesson_title,
      items: lesson.items.map((item) => ({
        prompt_text: item.prompt_text,
        glyph: item.glyph,
        difficulty: item.difficulty,
      })),
      item_count: lesson.items.length,
      course_id: DRAFT_COURSE_ID,
      published: false,
      corrections: verificationNotes,
      message:
        "Generated and validated. Review in the AI-Generated Lessons (Draft) " +
        "course, then approve to move the unit into the published course.",
    });
  }),
};
