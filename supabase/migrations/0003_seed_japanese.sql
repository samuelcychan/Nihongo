-- Convert the seed course "First Words: Animals" from Spanish to Japanese.
-- Idempotent: re-running re-applies the same Japanese content.
--
-- Reuses the fixed UUIDs from 0002_seed.sql so existing deep-links keep working.
-- The client matches answers by item id (not text), so swapping prompt_text /
-- answer here needs no app change — only the displayed/spoken word changes.

-- Course: now teaches Japanese to English speakers.
update public.courses set
    title           = 'First Words: Animals',
    ui_language     = 'en',
    target_language = 'ja',
    description     = 'Match spoken Japanese animal words to their pictures.',
    published       = true
where id = '11111111-1111-1111-1111-111111111111';

-- (unit / lesson / activity titles are language-neutral; left as-is:
--  "Around the Farm" / "Farm Animals" / "Tap the Animal".)

-- Replace the six items with their Japanese equivalents (same emoji pictures,
-- same difficulty curve and order).
delete from public.items
where activity_id = '44444444-4444-4444-4444-444444444444';

insert into public.items
  (activity_id, prompt_text, glyph, answer, difficulty, position) values
  ('44444444-4444-4444-4444-444444444444', 'ねこ',   '🐱', 'ねこ',   1, 0),
  ('44444444-4444-4444-4444-444444444444', 'いぬ',   '🐶', 'いぬ',   1, 1),
  ('44444444-4444-4444-4444-444444444444', 'とり',   '🐦', 'とり',   2, 2),
  ('44444444-4444-4444-4444-444444444444', 'さかな', '🐟', 'さかな', 2, 3),
  ('44444444-4444-4444-4444-444444444444', 'うし',   '🐮', 'うし',   3, 4),
  ('44444444-4444-4444-4444-444444444444', 'あひる', '🦆', 'あひる', 3, 5);

-- TTS note: flutter_tts must have a Japanese voice available to pronounce these
-- (set the engine locale to 'ja-JP' in AudioService). Where a native-speaker
-- clip exists, set prompt_audio_url and the client uses it instead of TTS.
