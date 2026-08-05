-- Expose latitude and longitude as plain columns.
--
-- PostgREST's `select` takes column names, aliases and casts — not function
-- calls. Asking it for `ST_Y(geom::geometry)` makes it look for a foreign key
-- relationship to a table called ST_Y and fail with a confusing error.
--
-- Generated columns rather than a view: `geom` stays the single authoritative
-- position, these two can never drift from it, and the client gets to select
-- them like any other column. The cost is a little storage per row, which for
-- twelve checkpoints is nothing.
--
-- Schema-qualified because PostGIS lives in `extensions`, and a generated
-- column resolves its expression at creation time against whatever
-- search_path happens to be set when the migration runs.

alter table public.checkpoints
  add column latitude double precision
    generated always as (extensions.st_y(geom::extensions.geometry)) stored,
  add column longitude double precision
    generated always as (extensions.st_x(geom::extensions.geometry)) stored;

comment on column public.checkpoints.latitude is
  'Derived from geom. Read-only; write geom instead.';
comment on column public.checkpoints.longitude is
  'Derived from geom. Read-only; write geom instead.';
