-- Sample published course for the vertical slice: "Animals" (English UI, Japanese target).
-- One unit -> one lesson -> one 'match' activity -> six animal items with emoji glyphs.
-- Fixed UUIDs so the client can deep-link the seed lesson during development.

insert into public.courses (id, title, ui_language, target_language, description, published)
values ('11111111-1111-1111-1111-111111111111',
        'First Words: Animals', 'en', 'ja',
        'Match spoken Japanese animal words to their pictures.', true)
on conflict (id) do update set
  published = excluded.published,
  target_language = excluded.target_language,
  description = excluded.description;

insert into public.units (id, course_id, title, position)
values ('22222222-2222-2222-2222-222222222222',
        '11111111-1111-1111-1111-111111111111', 'Around the Farm', 0)
on conflict (id) do nothing;

insert into public.lessons (id, unit_id, title, position)
values ('33333333-3333-3333-3333-333333333333',
        '22222222-2222-2222-2222-222222222222', 'Farm Animals', 0)
on conflict (id) do nothing;

insert into public.activities (id, lesson_id, type, title, position, config)
values ('44444444-4444-4444-4444-444444444444',
        '33333333-3333-3333-3333-333333333333', 'match', 'Tap the Animal', 0,
        '{"optionCount": 4, "speak": true}'::jsonb)
on conflict (id) do nothing;

insert into public.items (activity_id, prompt_text, glyph, answer, difficulty, position) values
  ('44444444-4444-4444-4444-444444444444', 'ねこ',   '🐱', 'ねこ',   1, 0),  -- neko (cat)
  ('44444444-4444-4444-4444-444444444444', 'いぬ',   '🐶', 'いぬ',   1, 1),  -- inu (dog)
  ('44444444-4444-4444-4444-444444444444', 'とり',   '🐦', 'とり',   2, 2),  -- tori (bird)
  ('44444444-4444-4444-4444-444444444444', 'さかな', '🐟', 'さかな', 2, 3),  -- sakana (fish)
  ('44444444-4444-4444-4444-444444444444', 'うし',   '🐮', 'うし',   3, 4),  -- ushi (cow)
  ('44444444-4444-4444-4444-444444444444', 'あひる', '🦆', 'あひる', 3, 5)   -- ahiru (duck)
on conflict do nothing;
