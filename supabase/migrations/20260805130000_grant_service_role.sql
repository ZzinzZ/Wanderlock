-- Privileges for the trusted backend role.
--
-- The first migration granted only `authenticated` and stopped there, which
-- left the two things that matter most unable to work: the seed script and the
-- check-in edge function both run as `service_role`.
--
-- Hosted Supabase usually has default privileges that cover this, so the gap
-- would have stayed invisible until the first deploy. It surfaced here because
-- the local stack starts from a bare database — which is a good argument for
-- developing against local rather than against a project that has been
-- hand-tweaked in a dashboard.

grant select, insert, update, delete on all tables in schema public
  to service_role;
grant usage, select on all sequences in schema public to service_role;

-- So a table added by a later migration is not silently unusable by the
-- backend. Applies to tables created by the migration role.
alter default privileges in schema public
  grant select, insert, update, delete on tables to service_role;
alter default privileges in schema public
  grant usage, select on sequences to service_role;

-- Deliberately NOT done for `authenticated`. Every table that role can touch
-- is granted one at a time, on purpose: a new table must be an explicit
-- decision about what a client may read, never something it inherits by
-- default. Getting that wrong is how user data leaks.
