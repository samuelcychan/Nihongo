-- The AI lesson generator (generate-lesson Edge Function) is gaining a
-- teacher-selectable activity type (match / drag_drop / sequence), matching
-- the client-side pages already shipped in M1 (DragDropActivityPage,
-- SequenceActivityPage). 'sequence' was already allowed; 'drag_drop' was not
-- -- add it to the same check constraint from 0001_init.sql.
alter table public.activities drop constraint activities_type_check;
alter table public.activities add constraint activities_type_check
  check (type in ('match', 'trace', 'sequence', 'speak', 'drag_drop'));
