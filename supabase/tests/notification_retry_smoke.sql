-- Notification retry smoke test
-- Purpose: verify retry columns exist and candidates can be selected safely.

begin;

select id, status, retry_count, next_retry_at
from public.notification_dispatch_logs
where status = 'failed'
order by dispatched_at desc
limit 20;

commit;
