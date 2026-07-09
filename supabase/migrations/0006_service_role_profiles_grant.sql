-- The teacher-role authorization check added to generate-lesson's approve/
-- reject actions reads public.profiles via ctx.supabaseAdmin (service_role)
-- to verify the caller's role. service_role bypasses RLS but not table-level
-- grants -- same class of gap as 0005_service_role_grants.sql, just on a
-- table that wasn't part of the generator's write path until this auth
-- check was added. Confirmed live: the lookup failed with
-- "permission denied for table profiles" until this grant.

grant select on public.profiles to service_role;
