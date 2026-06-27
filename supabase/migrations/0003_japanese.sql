-- Switch the seed course's target language from Spanish to Japanese.
-- Updates existing rows in place (item UUIDs are unchanged, so learner progress
-- in learner_item_states stays linked). Matches items by activity + position.

update public.courses
  set target_language = 'ja',
      description = 'Match spoken Japanese animal words to their pictures.'
  where id = '11111111-1111-1111-1111-111111111111';

update public.items set prompt_text = 'ねこ',   answer = 'ねこ'
  where activity_id = '44444444-4444-4444-4444-444444444444' and position = 0;
update public.items set prompt_text = 'いぬ',   answer = 'いぬ'
  where activity_id = '44444444-4444-4444-4444-444444444444' and position = 1;
update public.items set prompt_text = 'とり',   answer = 'とり'
  where activity_id = '44444444-4444-4444-4444-444444444444' and position = 2;
update public.items set prompt_text = 'さかな', answer = 'さかな'
  where activity_id = '44444444-4444-4444-4444-444444444444' and position = 3;
update public.items set prompt_text = 'うし',   answer = 'うし'
  where activity_id = '44444444-4444-4444-4444-444444444444' and position = 4;
update public.items set prompt_text = 'あひる', answer = 'あひる'
  where activity_id = '44444444-4444-4444-4444-444444444444' and position = 5;
