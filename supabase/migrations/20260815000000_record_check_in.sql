-- The check-in rule, in one place, in the database.
--
-- Why here and not in the edge function: the distance test and the write have
-- to be one transaction, and the rule has to be impossible to reach except
-- through the door that applies it. Putting the geometry in TypeScript would
-- mean the edge function computes a distance and then asks the table to trust
-- it — which is the same shape as trusting the client, one layer further in.
--
-- WHAT THIS CAN AND CANNOT PROVE. It proves that the position the caller
-- submitted is inside the checkpoint's radius, measured server-side against
-- the stored geometry. It cannot prove the position is real: a fabricated GPS
-- reading is still a reading. Detecting fabrication is a separate job —
-- mock-location flags and travel-speed checks — and it does not belong in a
-- geometry function. Keeping the two apart is what stops either from being
-- mistaken for the other.
--
-- Execute is granted to service_role ONLY. An authenticated client holding a
-- valid session still cannot call this: the sole caller is the check-in edge
-- function, which resolves the user from their JWT and passes the id it
-- verified rather than one the caller claimed.

create or replace function public.record_check_in(
  p_user_id uuid,
  p_checkpoint_id text,
  p_lat double precision,
  p_lon double precision,
  p_method public.verify_method
)
returns jsonb
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_geom geography(Point, 4326);
  v_radius_m integer;
  v_distance_m double precision;
  v_visit public.visit_state%rowtype;
begin
  select geom, radius_m into v_geom, v_radius_m
  from public.checkpoints
  where id = p_checkpoint_id;

  if not found then
    return jsonb_build_object('outcome', 'unknown_checkpoint');
  end if;

  -- Longitude first: ST_MakePoint takes x then y, the opposite of how a
  -- coordinate is spoken. Getting this backwards puts every checkpoint in the
  -- wrong hemisphere, which is far enough to look like a working rejection.
  v_distance_m := st_distance(
    v_geom,
    st_setsrid(st_makepoint(p_lon, p_lat), 4326)::geography
  );

  if v_distance_m > v_radius_m then
    return jsonb_build_object(
      'outcome', 'too_far',
      'distanceMeters', round(v_distance_m::numeric, 1),
      'radiusMeters', v_radius_m
    );
  end if;

  -- `do nothing`, not `do update`. A second arrival at the same place is not a
  -- new visit, and overwriting visited_at would quietly rewrite the day
  -- somebody first got there. This is the idempotence the whole unlock layer
  -- is built on.
  insert into public.visit_state (user_id, checkpoint_id, status, verified_by)
  values (p_user_id, p_checkpoint_id, 'visited', p_method)
  on conflict (user_id, checkpoint_id) do nothing;

  select * into v_visit
  from public.visit_state
  where user_id = p_user_id and checkpoint_id = p_checkpoint_id;

  return jsonb_build_object(
    'outcome', 'granted',
    'distanceMeters', round(v_distance_m::numeric, 1),
    'radiusMeters', v_radius_m,
    'visit', jsonb_build_object(
      'checkpoint_id', v_visit.checkpoint_id,
      'status', v_visit.status,
      'visited_at', v_visit.visited_at,
      'verified_by', v_visit.verified_by
    )
  );
end;
$$;

revoke all on function public.record_check_in(
  uuid, text, double precision, double precision, public.verify_method
) from public, anon, authenticated;

grant execute on function public.record_check_in(
  uuid, text, double precision, double precision, public.verify_method
) to service_role;
