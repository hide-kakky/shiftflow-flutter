import { isTokenInvalidError, sendFcmMessage } from "./fcm.ts";
import { createServiceClient } from "./supabase.ts";

type DispatchEvent = "new_message" | "new_task_assigned" | "task_due_tomorrow";

type QueueRow = {
  id: string;
  event_type: DispatchEvent;
  target_user_id: string;
  source_id: string;
};

type SubscriptionRow = {
  id: string;
  user_id: string;
  device_token: string | null;
};

function asString(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function nextRetryIso(minutes: number): string {
  return new Date(Date.now() + minutes * 60 * 1000).toISOString();
}

async function resolveMessageContent(
  service: ReturnType<typeof createServiceClient>,
  sourceId: string,
) {
  const { data } = await service
    .from("messages")
    .select("id,title,body")
    .eq("id", sourceId)
    .maybeSingle();
  if (!data) return null;

  return {
    title: `新規メッセージ: ${asString(data.title) || "タイトルなし"}`,
    body: asString(data.body),
    data: {
      eventType: "new_message",
      sourceId,
      title: asString(data.title),
      body: asString(data.body),
    },
  };
}

async function resolveTaskContent(
  service: ReturnType<typeof createServiceClient>,
  sourceId: string,
  eventType: DispatchEvent,
) {
  const { data } = await service
    .from("tasks")
    .select("id,title,description,due_at")
    .eq("id", sourceId)
    .maybeSingle();
  if (!data) return null;

  return {
    title: `${eventType === "task_due_tomorrow" ? "期限前日タスク" : "新規担当タスク"}: ${asString(data.title) || "タイトルなし"}`,
    body: asString(data.description),
    data: {
      eventType,
      sourceId,
      title: asString(data.title),
      body: asString(data.description),
      dueAt: asString(data.due_at),
    },
  };
}

async function resolveNotificationPayload(
  service: ReturnType<typeof createServiceClient>,
  row: QueueRow,
) {
  if (row.event_type === "new_message") {
    return resolveMessageContent(service, row.source_id);
  }
  return resolveTaskContent(service, row.source_id, row.event_type);
}

async function markInvalidSubscription(
  service: ReturnType<typeof createServiceClient>,
  subscriptionId: string,
) {
  await service
    .from("notification_subscriptions")
    .update({
      notification_opt_in: false,
      revoked_at: new Date().toISOString(),
    })
    .eq("id", subscriptionId);
}

async function markDispatchResult(
  service: ReturnType<typeof createServiceClient>,
  rowId: string,
  ok: boolean,
  errorMessage: string | null,
) {
  await service
    .from("notification_dispatch_logs")
    .update({
      status: ok ? "sent" : "failed",
      error_message: errorMessage,
      dispatched_at: new Date().toISOString(),
      next_retry_at: ok ? null : nextRetryIso(5),
    })
    .eq("id", rowId);
}

type DispatchOptions = {
  limit?: number;
  sourceId?: string;
  eventType?: DispatchEvent;
};

export async function dispatchQueuedNotifications(options: DispatchOptions = {}) {
  const service = createServiceClient();
  const limit = Math.max(1, Math.min(options.limit ?? 100, 500));

  let query = service
    .from("notification_dispatch_logs")
    .select("id,event_type,target_user_id,source_id")
    .eq("status", "queued")
    .order("dispatched_at", { ascending: true })
    .limit(limit);

  if (options.sourceId) {
    query = query.eq("source_id", options.sourceId);
  }
  if (options.eventType) {
    query = query.eq("event_type", options.eventType);
  }

  const { data: rows, error } = await query;
  if (error) throw error;

  const queueRows = (rows ?? []) as QueueRow[];
  if (queueRows.length === 0) {
    return { scanned: 0, sent: 0, failed: 0 };
  }

  const targetUserIds = [...new Set(queueRows.map((row) => row.target_user_id))];
  const { data: subscriptions, error: subscriptionError } = await service
    .from("notification_subscriptions")
    .select("id,user_id,device_token")
    .eq("provider", "fcm")
    .eq("notification_opt_in", true)
    .is("revoked_at", null)
    .in("user_id", targetUserIds);

  if (subscriptionError) throw subscriptionError;

  const subscriptionsByUser = new Map<string, SubscriptionRow[]>();
  for (const subscription of (subscriptions ?? []) as SubscriptionRow[]) {
    const current = subscriptionsByUser.get(subscription.user_id) ?? [];
    current.push(subscription);
    subscriptionsByUser.set(subscription.user_id, current);
  }

  let sent = 0;
  let failed = 0;

  for (const row of queueRows) {
    const payload = await resolveNotificationPayload(service, row);
    if (!payload) {
      await markDispatchResult(service, row.id, false, "source_not_found");
      failed += 1;
      continue;
    }

    const targets = (subscriptionsByUser.get(row.target_user_id) ?? [])
      .filter((subscription) => asString(subscription.device_token).length > 0);

    if (targets.length == 0) {
      await markDispatchResult(service, row.id, false, "no_active_subscription");
      failed += 1;
      continue;
    }

    const errors: string[] = [];
    let delivered = 0;

    for (const target of targets) {
      try {
        await sendFcmMessage({
          token: target.device_token!,
          title: payload.title,
          body: payload.body,
          data: payload.data,
        });
        delivered += 1;
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        errors.push(message);
        if (isTokenInvalidError(error)) {
          await markInvalidSubscription(service, target.id);
        }
      }
    }

    if (delivered > 0) {
      await markDispatchResult(service, row.id, true, null);
      sent += 1;
    } else {
      await markDispatchResult(
        service,
        row.id,
        false,
        errors.join(" | ") || "send_failed",
      );
      failed += 1;
    }
  }

  return {
    scanned: queueRows.length,
    sent,
    failed,
  };
}
