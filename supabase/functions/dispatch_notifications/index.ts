import { createServiceClient } from '../_shared/supabase.ts';
import { corsHeaders, decodeJwtPayload, jsonResponse, readBearerToken } from '../_shared/cors.ts';
import { dispatchQueuedNotifications } from '../_shared/notification_dispatch.ts';

function asString(value: unknown): string {
  return typeof value === 'string' ? value.trim() : '';
}

function asList(value: unknown): string[] {
  return Array.isArray(value)
    ? value.map((v) => asString(v)).filter((v) => v.length > 0)
    : [];
}

async function resolveActor(request: Request) {
  const token = readBearerToken(request);
  const payload = decodeJwtPayload(token);
  const authUserId = asString(payload.sub);
  if (!authUserId) return null;

  const service = createServiceClient();
  const { data: user } = await service
    .from('users')
    .select('id,email')
    .eq('auth_user_id', authUserId)
    .maybeSingle();
  if (!user) return null;

  const { data: membership } = await service
    .from('memberships')
    .select('id,organization_id,role,status')
    .eq('user_id', user.id)
    .eq('status', 'active')
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();

  if (!membership) return null;
  return {
    userId: user.id,
    email: user.email,
    role: membership.role,
    orgId: membership.organization_id,
  };
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    if (request.method !== 'POST') {
      return jsonResponse(405, { ok: false, code: 'method_not_allowed', reason: 'POST required' });
    }

    const actor = await resolveActor(request);
    if (!actor || (actor.role !== 'admin' && actor.role !== 'manager')) {
      return jsonResponse(403, { ok: false, code: 'forbidden', reason: 'manager role required' });
    }

    const service = createServiceClient();
    const body = (await request.json().catch(() => ({}))) as Record<string, unknown>;

    const eventType = asString(body.eventType) as 'new_message' | 'new_task_assigned' | 'task_due_tomorrow' | '';
    const sourceId = asString(body.sourceId);
    const targetUserIds = asList(body.targetUserIds);
    const limit = Number(body.limit ?? 100);

    if (targetUserIds.length === 0) {
      const result = await dispatchQueuedNotifications({
        limit: Number.isFinite(limit) ? limit : 100,
        sourceId: sourceId || undefined,
        eventType: eventType || undefined,
      });
      return jsonResponse(200, { ok: true, result });
    }

    const safeEventType = eventType || 'new_message';
    const safeSourceId = sourceId || crypto.randomUUID();

    const rows = [];
    for (const userId of targetUserIds) {
      const { data: exists } = await service
        .from('notification_dispatch_logs')
        .select('id')
        .eq('event_type', safeEventType)
        .eq('source_id', safeSourceId)
        .eq('target_user_id', userId)
        .maybeSingle();
      if (exists) continue;
      const { data: inserted, error } = await service
        .from('notification_dispatch_logs')
        .insert({
          event_type: safeEventType,
          organization_id: actor.orgId,
          target_user_id: userId,
          source_id: safeSourceId,
          status: 'queued',
        })
        .select('*')
        .single();
      if (error) throw error;
      rows.push(inserted);
    }

    const dispatched = await dispatchQueuedNotifications({
      sourceId: safeSourceId,
      eventType: safeEventType,
    });

    return jsonResponse(200, { ok: true, result: { queued: rows.length, rows, dispatched } });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(500, { ok: false, code: 'dispatch_failed', reason: message });
  }
});
