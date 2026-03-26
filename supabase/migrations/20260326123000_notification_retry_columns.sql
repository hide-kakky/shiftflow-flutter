-- Notification retry metadata
-- Adds minimal columns required to manage retry attempts for failed notifications.

begin;

alter table public.notification_dispatch_logs
  add column if not exists retry_count integer not null default 0,
  add column if not exists next_retry_at timestamptz;

alter table public.notification_dispatch_logs
  drop constraint if exists notification_dispatch_logs_retry_count_check;

alter table public.notification_dispatch_logs
  add constraint notification_dispatch_logs_retry_count_check
  check (retry_count >= 0);

create index if not exists idx_notification_dispatch_retry
  on public.notification_dispatch_logs (status, next_retry_at, retry_count);

commit;
