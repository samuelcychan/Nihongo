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

interface GeneratedItem {
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
          prompt_text: { type: "string", description: "The Japanese word/phrase." },
          answer: { type: "string", description: "Must equal prompt_text." },
          glyph: { type: "string", description: "A single emoji representing the word." },
          difficulty: { type: "integer", minimum: 1, maximum: 5 },
          category: { type: "string", description: "Broad category, e.g. 'animal', 'food'." },
        },
        required: ["prompt_text", "answer", "glyph", "difficulty", "category"],
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
          "unambiguous -- this is the only content a young child sees.",
      },
      { role: "user", content: `Topic: ${topic}` },
    ],
    "lesson",
    ITEM_SCHEMA,
  );
  return JSON.parse(content) as GeneratedLesson;
}

const VERIFICATION_SCHEMA = {
  type: "object",
  properties: {
    ok: { type: "boolean" },
    issues: { type: "array", items: { type: "string" } },
  },
  required: ["ok", "issues"],
  additionalProperties: false,
} as const;

/**
 * T4 -- translation-correctness mitigation (second-pass verification).
 *
 * Schema validation alone (T3) only proves the JSON is well-formed; it does
 * NOT catch a wrong-but-well-formed translation, the single worst failure
 * mode for this feature (a kid confidently learns the wrong word). This asks
 * a second, independent LLM call to fact-check each item and flags any it
 * isn't confident in rather than silently accepting them.
 */
async function verifyTranslations(
  lesson: GeneratedLesson,
): Promise<{ ok: true } | { ok: false; issues: string[] }> {
  const content = await callLLM(
    [
      {
        role: "system",
        content:
          "You are a strict Japanese-language fact-checker. Given a list " +
          "of (Japanese word, category) pairs, verify each word is a " +
          "correct, common, and unambiguous Japanese word for that " +
          "category -- appropriate for teaching a young English-speaking " +
          "child. Return { ok: boolean, issues: string[] } -- ok is false " +
          "if ANY item is wrong, ambiguous, or inappropriate; issues " +
          "lists exactly what's wrong with which item (empty if ok).",
      },
      {
        role: "user",
        content: JSON.stringify(
          lesson.items.map((i) => ({ word: i.prompt_text, category: i.category })),
        ),
      },
    ],
    "verification",
    VERIFICATION_SCHEMA,
  );
  const result = JSON.parse(content) as { ok: boolean; issues: string[] };
  return result.ok ? { ok: true } : { ok: false, issues: result.issues };
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

export default {
  fetch: withSupabase({ auth: ["publishable"] }, async (req, ctx) => {
    let body: { action?: string; topic?: string; unit_id?: string };
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
      return handleReview(ctx.supabaseAdmin, action, body.unit_id);
    }

    const topic = body.topic;
    if (typeof topic !== "string" || !topic.trim()) {
      return Response.json({ error: "topic (non-empty string) is required" }, { status: 400 });
    }

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

    const validationErrors = validateLesson(lesson);
    if (validationErrors.length > 0) {
      return Response.json(
        { error: "generated lesson failed validation", details: validationErrors },
        { status: 422 },
      );
    }

    let verification: { ok: true } | { ok: false; issues: string[] };
    try {
      verification = await verifyTranslations(lesson);
    } catch (e) {
      const err = e as Error;
      return Response.json(
        { error: `translation verification failed: ${err.message}` },
        { status: 502 },
      );
    }
    if (!verification.ok) {
      return Response.json(
        {
          error: "generated lesson failed translation-correctness verification",
          details: verification.issues,
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
        type: "match",
        title: lesson.lesson_title,
        position: 0,
        config: { optionCount: 4, speak: true },
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
      lesson_title: lesson.lesson_title,
      items: lesson.items.map((item) => ({
        prompt_text: item.prompt_text,
        glyph: item.glyph,
        difficulty: item.difficulty,
      })),
      item_count: lesson.items.length,
      course_id: DRAFT_COURSE_ID,
      published: false,
      message:
        "Generated and validated. Review in the AI-Generated Lessons (Draft) " +
        "course, then approve to move the unit into the published course.",
    });
  }),
};
