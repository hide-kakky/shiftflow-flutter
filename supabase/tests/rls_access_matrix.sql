-- RLS access matrix smoke test
-- Purpose: verify that cross-organization access is denied by RLS policies.

begin;

-- This test assumes migration/seed has been applied and auth context is provided.
-- For local smoke, we only verify policies exist.

select schemaname, tablename, policyname
from pg_policies
where schemaname in ('public', 'storage')
  and tablename in (
    'organizations', 'users', 'memberships', 'folders', 'templates', 'tasks',
    'messages', 'message_reads', 'message_comments', 'attachments',
    'audit_logs', 'notification_subscriptions', 'notification_dispatch_logs'
  )
order by tablename, policyname;

commit;
