-- M1: Supabase Storage bucket for lesson media (item images + native-speaker
-- audio clips referenced by items.image_url / items.prompt_audio_url).
--
-- Public read, same posture as published content tables -- anon/authenticated
-- learners load images/audio with no auth friction. Writes are restricted to
-- service_role: there is no client-side upload path yet (uploads happen via
-- the generate-lesson Edge Function or a future teacher-authoring flow), so
-- anon/authenticated get no insert/update/delete grant here, matching the
-- content-table pattern in 0001_init.sql.

insert into storage.buckets (id, name, public)
values ('media', 'media', true)
on conflict (id) do nothing;

create policy "media_public_read" on storage.objects
  for select using (bucket_id = 'media');

create policy "media_service_role_write" on storage.objects
  for insert to service_role with check (bucket_id = 'media');

create policy "media_service_role_update" on storage.objects
  for update to service_role using (bucket_id = 'media');

create policy "media_service_role_delete" on storage.objects
  for delete to service_role using (bucket_id = 'media');
