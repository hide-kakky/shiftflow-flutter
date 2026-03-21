import { createServiceClient } from '../_shared/supabase.ts';
import { corsHeaders, jsonResponse } from '../_shared/cors.ts';

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const service = createServiceClient();

    const now = new Date();
    const tomorrowStart = new Date(now);
    tomorrowStart.setDate(tomorrowStart.getDate() + 1);
    tomorrowStart.setHours(0, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrowStart);
    tomorrowEnd.setHours(23, 59, 59, 999);

    const { data: dueTasks, error } = await service
      .from('tasks')
      .select('id,organization_id,due_at,status,task_assignees(user_id)')
      .gte('due_at', tomorrowStart.toISOString())
      .lte('due_at', tomorrowEnd.toISOString())
      .not('status', 'in', '(completed,canceled)');

    if (error) throw error;

    let queued = 0;

    for (const task of dueTasks ?? []) {
      const assignees = Array.isArray(task.task_assignees)
        ? task.task_assignees.map((x: { user_id: string }) => x.user_id).filter(Boolean)
        : [];

      for (const userId of assignees) {
        const { data: exists } = await service
          .from('notification_dispatch_logs')
          .select('id')
          .eq('event_type', 'task_due_tomorrow')
          .eq('source_id', task.id)
          .eq('target_user_id', userId)
          .maybeSingle();

        if (exists) continue;

        const { error: insertError } = await service
          .from('notification_dispatch_logs')
          .insert({
            event_type: 'task_due_tomorrow',
            organization_id: task.organization_id,
            target_user_id: userId,
            source_id: task.id,
            status: 'queued',
          });

        if (insertError) throw insertError;
        queued += 1;
      }
    }

    return jsonResponse(200, {
      ok: true,
      result: {
        checked: dueTasks?.length ?? 0,
        queued,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(500, { ok: false, code: 'notify_due_tasks_failed', reason: message });
  }
});
