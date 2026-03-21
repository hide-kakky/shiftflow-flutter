-- Notification dispatch dedup smoke test
-- Purpose: ensure duplicate delivery rows can be detected by key tuple.

begin;

select event_type, source_id, target_user_id, count(*) as duplicated
from public.notification_dispatch_logs
group by event_type, source_id, target_user_id
having count(*) > 1;

commit;
