-- ShiftFlow Flutter + Supabase unified schema
create extension if not exists "pgcrypto";

create schema if not exists app;

create type app.user_role as enum ('admin', 'manager', 'member', 'guest');
create type app.member_status as enum ('pending', 'active', 'suspended', 'revoked');
create type app.task_status as enum ('open', 'in_progress', 'on_hold', 'completed', 'canceled');
create type app.priority_level as enum ('low', 'medium', 'high');
create type app.dispatch_event as enum ('new_message', 'new_task_assigned', 'task_due_tomorrow');

create table if not exists public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  short_name text,
  display_color text,
  timezone text not null default 'Asia/Tokyo',
  notification_email text,
  meta_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  auth_user_id uuid unique,
  email text not null unique,
  display_name text,
  profile_image_url text,
  language text not null default 'ja',
  theme text not null default 'system',
  status app.member_status not null default 'pending',
  is_active boolean not null default false,
  approved_by text,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.memberships (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role app.user_role not null default 'member',
  status app.member_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

create table if not exists public.folders (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  name text not null,
  sort_order int not null default 0,
  color text,
  is_active boolean not null default true,
  is_public boolean not null default true,
  is_system boolean not null default false,
  archived_at timestamptz,
  archive_year int,
  archive_category text,
  notes text,
  meta_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.folder_members (
  folder_id uuid not null references public.folders(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (folder_id, user_id)
);

create table if not exists public.templates (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  folder_id uuid not null references public.folders(id) on delete cascade,
  name text not null,
  title_format text,
  body_format text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  folder_id uuid references public.folders(id) on delete set null,
  title text not null,
  description text,
  status app.task_status not null default 'open',
  priority app.priority_level not null default 'medium',
  created_by_user_id uuid references public.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  due_at timestamptz,
  legacy_task_id text,
  meta_json jsonb not null default '{}'::jsonb
);

create table if not exists public.task_assignees (
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (task_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  folder_id uuid references public.folders(id) on delete set null,
  author_membership_id uuid references public.memberships(id) on delete set null,
  title text,
  body text,
  priority app.priority_level not null default 'medium',
  is_pinned boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.message_reads (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  membership_id uuid not null references public.memberships(id) on delete cascade,
  read_at timestamptz not null default now(),
  unique (message_id, membership_id)
);

create table if not exists public.message_comments (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  membership_id uuid references public.memberships(id) on delete set null,
  author_email text,
  author_display_name text,
  body text not null,
  mentions text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.attachments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  file_name text,
  content_type text,
  size_bytes bigint,
  storage_path text,
  checksum text,
  created_at timestamptz not null default now(),
  created_by_membership_id uuid references public.memberships(id) on delete set null,
  extra_json jsonb not null default '{}'::jsonb
);

create table if not exists public.task_attachments (
  task_id uuid not null references public.tasks(id) on delete cascade,
  attachment_id uuid not null references public.attachments(id) on delete cascade,
  primary key (task_id, attachment_id)
);

create table if not exists public.message_attachments (
  message_id uuid not null references public.messages(id) on delete cascade,
  attachment_id uuid not null references public.attachments(id) on delete cascade,
  primary key (message_id, attachment_id)
);

create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  actor_membership_id uuid references public.memberships(id) on delete set null,
  target_type text not null,
  target_id text,
  action text not null,
  payload_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.login_audits (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references public.organizations(id) on delete set null,
  user_email text,
  user_sub text,
  status app.member_status,
  reason text,
  request_id text,
  attempted_at timestamptz not null default now(),
  client_ip text,
  user_agent text,
  role app.user_role
);

create table if not exists public.auth_proxy_logs (
  id uuid primary key default gen_random_uuid(),
  level text,
  event text,
  message text,
  request_id text,
  route text,
  email text,
  status text,
  meta_json jsonb not null default '{}'::jsonb,
  source text,
  client_ip text,
  user_agent text,
  created_at timestamptz not null default now()
);

create table if not exists public.notification_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  endpoint text not null,
  p256dh text not null,
  auth text not null,
  ua_hash text,
  platform text,
  notification_opt_in boolean not null default true,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, endpoint)
);

create table if not exists public.notification_dispatch_logs (
  id uuid primary key default gen_random_uuid(),
  event_type app.dispatch_event not null,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  target_user_id uuid not null references public.users(id) on delete cascade,
  source_id text,
  dispatched_at timestamptz not null default now(),
  status text not null default 'sent',
  error_message text
);

create index if not exists idx_memberships_org_status on public.memberships(organization_id, status);
create index if not exists idx_tasks_org_status on public.tasks(organization_id, status);
create index if not exists idx_messages_org_created on public.messages(organization_id, created_at desc);
create index if not exists idx_notification_dispatch_unique on public.notification_dispatch_logs(event_type, source_id, target_user_id);
create unique index if not exists uq_folders_org_lower_name on public.folders(organization_id, lower(name));

create or replace function app.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_org_touch before update on public.organizations
for each row execute procedure app.touch_updated_at();

create trigger trg_user_touch before update on public.users
for each row execute procedure app.touch_updated_at();

create trigger trg_folder_touch before update on public.folders
for each row execute procedure app.touch_updated_at();

create trigger trg_template_touch before update on public.templates
for each row execute procedure app.touch_updated_at();

create trigger trg_task_touch before update on public.tasks
for each row execute procedure app.touch_updated_at();

create trigger trg_message_touch before update on public.messages
for each row execute procedure app.touch_updated_at();

create trigger trg_message_comment_touch before update on public.message_comments
for each row execute procedure app.touch_updated_at();

create trigger trg_notification_subscriptions_touch before update on public.notification_subscriptions
for each row execute procedure app.touch_updated_at();

create or replace function app.current_user_id()
returns uuid
language sql
stable
as $$
  select u.id
  from public.users u
  where u.auth_user_id = auth.uid()
  limit 1;
$$;

create or replace function app.has_membership(org_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.memberships m
    where m.organization_id = org_id
      and m.user_id = app.current_user_id()
      and m.status = 'active'
  );
$$;

create or replace function app.has_role(org_id uuid, allowed app.user_role[])
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.memberships m
    where m.organization_id = org_id
      and m.user_id = app.current_user_id()
      and m.status = 'active'
      and m.role = any (allowed)
  );
$$;

alter table public.organizations enable row level security;
alter table public.users enable row level security;
alter table public.memberships enable row level security;
alter table public.folders enable row level security;
alter table public.folder_members enable row level security;
alter table public.templates enable row level security;
alter table public.tasks enable row level security;
alter table public.task_assignees enable row level security;
alter table public.messages enable row level security;
alter table public.message_reads enable row level security;
alter table public.message_comments enable row level security;
alter table public.attachments enable row level security;
alter table public.task_attachments enable row level security;
alter table public.message_attachments enable row level security;
alter table public.audit_logs enable row level security;
alter table public.login_audits enable row level security;
alter table public.auth_proxy_logs enable row level security;
alter table public.notification_subscriptions enable row level security;
alter table public.notification_dispatch_logs enable row level security;

create policy org_read on public.organizations
for select using (app.has_membership(id));

create policy org_admin_update on public.organizations
for update using (app.has_role(id, array['admin','manager']::app.user_role[]))
with check (app.has_role(id, array['admin','manager']::app.user_role[]));

create policy user_read on public.users
for select using (
  id = app.current_user_id()
  or exists (
    select 1 from public.memberships m1
    join public.memberships m2 on m2.organization_id = m1.organization_id
    where m1.user_id = app.current_user_id()
      and m2.user_id = users.id
      and m1.status = 'active'
      and m2.status = 'active'
  )
);

create policy user_self_update on public.users
for update using (id = app.current_user_id())
with check (id = app.current_user_id());

create policy membership_read on public.memberships
for select using (organization_id in (
  select organization_id from public.memberships where user_id = app.current_user_id() and status = 'active'
));

create policy membership_admin_write on public.memberships
for all using (app.has_role(organization_id, array['admin','manager']::app.user_role[]))
with check (app.has_role(organization_id, array['admin','manager']::app.user_role[]));

create policy folders_read on public.folders
for select using (
  app.has_membership(organization_id)
  and (
    is_public = true
    or app.has_role(organization_id, array['admin','manager']::app.user_role[])
    or exists (
      select 1 from public.folder_members fm
      where fm.folder_id = folders.id
        and fm.user_id = app.current_user_id()
    )
  )
);

create policy folders_manager_write on public.folders
for all using (app.has_role(organization_id, array['admin','manager']::app.user_role[]))
with check (app.has_role(organization_id, array['admin','manager']::app.user_role[]));

create policy folder_members_read on public.folder_members
for select using (
  exists (
    select 1 from public.folders f
    where f.id = folder_members.folder_id
      and app.has_membership(f.organization_id)
  )
);

create policy folder_members_write on public.folder_members
for all using (
  exists (
    select 1 from public.folders f
    where f.id = folder_members.folder_id
      and app.has_role(f.organization_id, array['admin','manager']::app.user_role[])
  )
)
with check (
  exists (
    select 1 from public.folders f
    where f.id = folder_members.folder_id
      and app.has_role(f.organization_id, array['admin','manager']::app.user_role[])
  )
);

create policy templates_read on public.templates
for select using (app.has_membership(organization_id));

create policy templates_manager_write on public.templates
for all using (app.has_role(organization_id, array['admin','manager']::app.user_role[]))
with check (app.has_role(organization_id, array['admin','manager']::app.user_role[]));

create policy tasks_read on public.tasks
for select using (app.has_membership(organization_id));

create policy tasks_write on public.tasks
for all using (app.has_membership(organization_id))
with check (app.has_membership(organization_id));

create policy task_assignees_read on public.task_assignees
for select using (
  exists (
    select 1 from public.tasks t
    where t.id = task_assignees.task_id
      and app.has_membership(t.organization_id)
  )
);

create policy task_assignees_write on public.task_assignees
for all using (
  exists (
    select 1 from public.tasks t
    where t.id = task_assignees.task_id
      and app.has_membership(t.organization_id)
  )
)
with check (
  exists (
    select 1 from public.tasks t
    where t.id = task_assignees.task_id
      and app.has_membership(t.organization_id)
  )
);

create policy messages_read on public.messages
for select using (app.has_membership(organization_id));

create policy messages_write on public.messages
for all using (app.has_membership(organization_id))
with check (app.has_membership(organization_id));

create policy message_reads_rw on public.message_reads
for all using (
  exists (
    select 1
    from public.messages m
    where m.id = message_reads.message_id
      and app.has_membership(m.organization_id)
  )
)
with check (
  exists (
    select 1
    from public.messages m
    where m.id = message_reads.message_id
      and app.has_membership(m.organization_id)
  )
);

create policy message_comments_rw on public.message_comments
for all using (app.has_membership(organization_id))
with check (app.has_membership(organization_id));

create policy attachments_rw on public.attachments
for all using (app.has_membership(organization_id))
with check (app.has_membership(organization_id));

create policy task_attachments_rw on public.task_attachments
for all using (
  exists (
    select 1 from public.tasks t
    where t.id = task_attachments.task_id
      and app.has_membership(t.organization_id)
  )
)
with check (
  exists (
    select 1 from public.tasks t
    where t.id = task_attachments.task_id
      and app.has_membership(t.organization_id)
  )
);

create policy message_attachments_rw on public.message_attachments
for all using (
  exists (
    select 1 from public.messages m
    where m.id = message_attachments.message_id
      and app.has_membership(m.organization_id)
  )
)
with check (
  exists (
    select 1 from public.messages m
    where m.id = message_attachments.message_id
      and app.has_membership(m.organization_id)
  )
);

create policy audit_logs_read on public.audit_logs
for select using (app.has_role(organization_id, array['admin','manager']::app.user_role[]));

create policy login_audits_read on public.login_audits
for select using (
  organization_id is not null
  and app.has_role(organization_id, array['admin','manager']::app.user_role[])
);

create policy auth_proxy_logs_read on public.auth_proxy_logs
for select using (exists (
  select 1 from public.memberships m
  where m.user_id = app.current_user_id()
    and m.status = 'active'
    and m.role in ('admin', 'manager')
));

create policy notification_subscriptions_rw on public.notification_subscriptions
for all using (user_id = app.current_user_id())
with check (user_id = app.current_user_id());

create policy notification_dispatch_read on public.notification_dispatch_logs
for select using (
  target_user_id = app.current_user_id()
  or app.has_role(organization_id, array['admin','manager']::app.user_role[])
);

insert into storage.buckets (id, name, public)
values ('profiles', 'profiles', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', false)
on conflict (id) do nothing;

create policy profiles_rw on storage.objects
for all
using (
  bucket_id = 'profiles' and auth.role() = 'authenticated'
)
with check (
  bucket_id = 'profiles'
  and auth.role() = 'authenticated'
  and coalesce(metadata->>'mimetype', '') in ('image/png', 'image/jpeg', 'image/webp')
  and coalesce((nullif(metadata->>'size', ''))::bigint, 0) <= 2097152
);

create policy attachments_rw on storage.objects
for all
using (
  bucket_id = 'attachments' and auth.role() = 'authenticated'
)
with check (
  bucket_id = 'attachments'
  and auth.role() = 'authenticated'
  and coalesce(metadata->>'mimetype', '') in (
    'application/pdf',
    'application/zip',
    'text/plain',
    'text/csv',
    'image/png',
    'image/jpeg',
    'image/webp'
  )
  and coalesce((nullif(metadata->>'size', ''))::bigint, 0) <= 10485760
);
