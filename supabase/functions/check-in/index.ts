// Check-in: the only door to the unlock layer.
//
// The client never decides it has arrived. It sends where it thinks it is and
// this function, holding the service role, asks the database to measure the
// distance against the stored checkpoint and write the visit if it fits. A
// request built by hand with curl goes down exactly the same path: no session,
// no unlock; wrong position, no unlock.
//
// The user id is taken from the verified JWT, never from the body. A body
// field naming the user would let anyone unlock anyone's map.
//
// Not implemented here on purpose: proving the submitted position is genuine.
// See the note in migrations/20260815000000_record_check_in.sql — mock-location
// and travel-speed checks are separate work and must not be confused with this.

import { createClient } from 'jsr:@supabase/supabase-js@2';

interface CheckInRequest {
  checkpointId: string;
  lat: number;
  lon: number;
  method?: string;
}

const jsonHeaders = { 'Content-Type': 'application/json; charset=utf-8' };

function fail(status: number, error: string, extra: Record<string, unknown> = {}) {
  return new Response(JSON.stringify({ error, ...extra }), {
    status,
    headers: jsonHeaders,
  });
}

/// Rejects anything that is not a finite coordinate in range.
///
/// NaN and Infinity matter more than they look: both survive JSON.parse from a
/// hand-built body, and both make a distance comparison answer false rather
/// than throw — which would read as "inside the radius".
function isValidCoordinate(lat: unknown, lon: unknown): lat is number {
  return (
    typeof lat === 'number' &&
    typeof lon === 'number' &&
    Number.isFinite(lat) &&
    Number.isFinite(lon) &&
    lat >= -90 &&
    lat <= 90 &&
    lon >= -180 &&
    lon <= 180
  );
}

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') {
    return fail(405, 'method_not_allowed');
  }

  const authorization = request.headers.get('Authorization');
  if (!authorization) {
    return fail(401, 'missing_authorization');
  }

  const url = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!url || !serviceRoleKey) {
    console.error('check-in: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY missing');
    return fail(500, 'server_misconfigured');
  }

  const admin = createClient(url, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  // Resolve the caller from their token. This is the only place a user id
  // enters the request, and it comes from a signature the client cannot forge.
  const token = authorization.replace(/^Bearer\s+/i, '');
  const { data: userData, error: userError } = await admin.auth.getUser(token);
  if (userError || !userData?.user) {
    return fail(401, 'invalid_session');
  }

  let body: CheckInRequest;
  try {
    body = await request.json();
  } catch {
    return fail(400, 'malformed_body');
  }

  if (typeof body?.checkpointId !== 'string' || body.checkpointId.length === 0) {
    return fail(400, 'missing_checkpoint_id');
  }
  if (!isValidCoordinate(body.lat, body.lon)) {
    return fail(400, 'invalid_coordinates');
  }

  // Only GPS is verifiable today. `qr` and `quiz` exist in the schema for the
  // places the S3 survey will mark as needing a fallback, but nothing issues
  // or validates a QR token yet — so accepting one would be an unlock with no
  // check behind it, which is worse than not offering it.
  const method = body.method ?? 'gps';
  if (method !== 'gps') {
    return fail(400, 'unsupported_method', { method });
  }

  const { data, error } = await admin.rpc('record_check_in', {
    p_user_id: userData.user.id,
    p_checkpoint_id: body.checkpointId,
    p_lat: body.lat,
    p_lon: body.lon,
    p_method: method,
  });

  if (error) {
    console.error('check-in: record_check_in failed', error);
    return fail(500, 'check_in_failed');
  }

  switch (data?.outcome) {
    case 'granted':
      return new Response(JSON.stringify(data), { status: 200, headers: jsonHeaders });
    case 'too_far':
      // 403 with the numbers: the app shows how much further there is to walk,
      // which is the only useful thing to say to someone standing outside.
      return fail(403, 'too_far', {
        distanceMeters: data.distanceMeters,
        radiusMeters: data.radiusMeters,
      });
    case 'unknown_checkpoint':
      return fail(404, 'unknown_checkpoint');
    default:
      console.error('check-in: unexpected outcome', data);
      return fail(500, 'check_in_failed');
  }
});
