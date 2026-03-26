import { createServiceClient } from "../_shared/supabase.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

function asNumber(value: unknown, fallback: number): number {
  const n = Number(value);
  return Number.isFinite(n) ? n : fallback;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (request.method !== "POST") {
      return jsonResponse(405, {
        ok: false,
        code: "method_not_allowed",
        reason: "POST required",
      });
    }

    const service = createServiceClient();
    const body = (await request.json().catch(() => ({}))) as Record<
      string,
      unknown
    >;

    const limit = Math.max(1, Math.min(500, asNumber(body.limit, 100)));
    const maxRetries = Math.max(1, Math.min(10, asNumber(body.maxRetries, 3)));
    const now = new Date();

    const { data: failedRows, error: selectError } = await service
      .from("notification_dispatch_logs")
      .select("id,status,retry_count,next_retry_at")
      .eq("status", "failed")
      .order("dispatched_at", { ascending: true })
      .limit(limit);

    if (selectError) throw selectError;

    let queued = 0;
    let exhausted = 0;
    let notDue = 0;

    for (const row of failedRows ?? []) {
      const retryCount = Number(row.retry_count ?? 0);
      const nextRetryAtRaw = typeof row.next_retry_at === "string"
        ? row.next_retry_at
        : "";
      const nextRetryAt = nextRetryAtRaw ? new Date(nextRetryAtRaw) : null;

      if (retryCount >= maxRetries) {
        exhausted += 1;
        continue;
      }

      if (nextRetryAt && nextRetryAt.getTime() > now.getTime()) {
        notDue += 1;
        continue;
      }

      const { error: updateError } = await service
        .from("notification_dispatch_logs")
        .update({
          status: "queued",
          retry_count: retryCount + 1,
          next_retry_at: null,
        })
        .eq("id", row.id)
        .eq("status", "failed");

      if (updateError) throw updateError;
      queued += 1;
    }

    return jsonResponse(200, {
      ok: true,
      result: {
        scanned: failedRows?.length ?? 0,
        queued,
        exhausted,
        notDue,
        maxRetries,
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return jsonResponse(500, {
      ok: false,
      code: "retry_failed_notifications_failed",
      reason: message,
    });
  }
});
