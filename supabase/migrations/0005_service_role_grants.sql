-- M0.5's generate-lesson Edge Function writes content via ctx.supabaseAdmin
-- (the service_role client). service_role bypasses RLS, but bypassing RLS
-- does NOT bypass table-level GRANTs -- and 0001_init.sql only ever granted
-- privileges to anon/authenticated (this schema was created via raw SQL, not
-- the dashboard, which is exactly the gotcha AGENTS.md already documents:
-- "raw-SQL migrations must grant explicitly"). Nothing needed service_role
-- write access before M0.5, so this was never added until now.
--
-- Scope: insert (generate), update (approve -- moves a unit's course_id),
-- delete (reject) on the content hierarchy the function touches.

grant select, insert, update, delete
  on public.courses, public.units, public.lessons, public.activities, public.items
  to service_role;
