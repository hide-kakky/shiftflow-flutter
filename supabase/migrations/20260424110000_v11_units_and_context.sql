do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'organization_role'
  ) then
    create type app.organization_role as enum ('owner', 'admin', 'member');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'unit_role'
  ) then
    create type app.unit_role as enum ('manager', 'member');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'message_scope'
  ) then
    create type app.message_scope as enum ('shared', 'direct');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_type t
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'context_type'
  ) then
    create type app.context_type as enum ('organization', 'unit', 'folder', 'message', 'task', 'direct_message', 'system');
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'dispatch_event' and e.enumlabel = 'new_direct_message'
  ) then
    alter type app.dispatch_event add value 'new_direct_message';
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'dispatch_event' and e.enumlabel = 'join_request_approved'
  ) then
    alter type app.dispatch_event add value 'join_request_approved';
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1 from pg_enum e
    join pg_type t on t.oid = e.enumtypid
    join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'app' and t.typname = 'dispatch_event' and e.enumlabel = 'organization_invite_accepted'
  ) then
    alter type app.dispatch_event add value 'organization_invite_accepted';
  end if;
end
$$;

alter table public.organizations
  add column if not exists organization_code text;

update public.organizations
set organization_code = lower(substring(replace(id::text, '-', '') from 1 for 8))
where organization_code is null or btrim(organization_code) = '';

create unique index if not exists uq_organizations_code on public.organizations(lower(organization_code));

alter table public.users
  add column if not exists current_organization_id uuid references public.organizations(id) on delete set null,
  add column if not exists current_unit_id uuid,
  add column if not exists last_context_changed_at timestamptz;

alter table public.memberships
  add column if not exists organization_role app.organization_role;

update public.memberships
set organization_role = case role
  when 'admin' then 'admin'::app.organization_role
  when 'manager' then 'admin'::app.organization_role
  else 'member'::app.organization_role
end
where organization_role is null;

alter table public.memberships
  alter column organization_role set default 'member';

create table if not exists public.units (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  parent_unit_id uuid references public.units(id) on delete cascade,
  name text not null,
  path_text text,
  sort_order int not null default 0,
  is_active boolean not null default true,
  meta_json jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists uq_units_org_parent_lower_name
  on public.units(organization_id, coalesce(parent_unit_id, '00000000-0000-0000-0000-000000000000'::uuid), lower(name));

create table if not exists public.unit_memberships (
  id uuid primary key default gen_random_uuid(),
  unit_id uuid not null references public.units(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role app.unit_role not null default 'member',
  status app.member_status not null default 'active',
  granted_by_membership_id uuid references public.memberships(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (unit_id, user_id)
);

create table if not exists public.organization_invites (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  unit_id uuid references public.units(id) on delete set null,
  invite_token text not null unique default encode(gen_random_bytes(18), 'hex'),
  invite_label text,
  role app.organization_role not null default 'member',
  expires_at timestamptz,
  accepted_by_user_id uuid references public.users(id) on delete set null,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_by_membership_id uuid references public.memberships(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.join_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  requested_unit_id uuid references public.units(id) on delete set null,
  user_id uuid not null references public.users(id) on delete cascade,
  requested_code text,
  request_message text,
  status app.member_status not null default 'pending',
  reviewed_by_membership_id uuid references public.memberships(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, user_id)
);

insert into public.units (organization_id, parent_unit_id, name, path_text, sort_order, is_active)
select o.id, null, coalesce(o.short_name, o.name), coalesce(o.short_name, o.name), 0, true
from public.organizations o
where not exists (
  select 1 from public.units u
  where u.organization_id = o.id and u.parent_unit_id is null
);

alter table public.folders
  add column if not exists unit_id uuid references public.units(id) on delete restrict;

update public.folders f
set unit_id = u.id
from public.units u
where f.unit_id is null
  and u.organization_id = f.organization_id
  and u.parent_unit_id is null;

alter table public.tasks
  add column if not exists unit_id uuid references public.units(id) on delete set null;

update public.tasks t
set unit_id = coalesce(
  (
    select f.unit_id
    from public.folders f
    where f.id = t.folder_id
  ),
  (
    select u.id
    from public.units u
    where u.organization_id = t.organization_id
      and u.parent_unit_id is null
    limit 1
  )
)
where t.unit_id is null;

alter table public.messages
  add column if not exists unit_id uuid references public.units(id) on delete set null,
  add column if not exists message_scope app.message_scope not null default 'shared',
  add column if not exists author_user_id uuid references public.users(id) on delete set null,
  add column if not exists recipient_user_id uuid references public.users(id) on delete cascade;

update public.messages m
set unit_id = coalesce(
  (
    select f.unit_id
    from public.folders f
    where f.id = m.folder_id
  ),
  (
    select u.id
    from public.units u
    where u.organization_id = m.organization_id
      and u.parent_unit_id is null
    limit 1
  )
)
where m.unit_id is null;

update public.messages m
set author_user_id = memberships.user_id
from public.memberships
where memberships.id = m.author_membership_id
  and m.author_user_id is null;

alter table public.message_reads
  add column if not exists user_id uuid references public.users(id) on delete cascade;

create unique index if not exists uq_message_reads_message_user
  on public.message_reads(message_id, user_id)
  where user_id is not null;

alter table public.attachments
  add column if not exists task_id uuid references public.tasks(id) on delete cascade,
  add column if not exists message_id uuid references public.messages(id) on delete cascade;

alter table public.audit_logs
  add column if not exists unit_id uuid references public.units(id) on delete set null,
  add column if not exists context_type app.context_type not null default 'system',
  add column if not exists before_json jsonb not null default '{}'::jsonb,
  add column if not exists after_json jsonb not null default '{}'::jsonb;

create index if not exists idx_units_org_parent on public.units(organization_id, parent_unit_id, sort_order);
create index if not exists idx_unit_memberships_user_status on public.unit_memberships(user_id, status);
create index if not exists idx_tasks_org_unit_status on public.tasks(organization_id, unit_id, status);
create index if not exists idx_messages_org_unit_scope on public.messages(organization_id, unit_id, message_scope, created_at desc);
create index if not exists idx_join_requests_org_status on public.join_requests(organization_id, status, created_at desc);
create index if not exists idx_invites_org_active on public.organization_invites(organization_id, revoked_at, accepted_at);

create or replace function app.touch_path_text()
returns trigger
language plpgsql
as $$
declare
  parent_path text;
begin
  if new.parent_unit_id is null then
    new.path_text = new.name;
    return new;
  end if;

  select path_text into parent_path
  from public.units
  where id = new.parent_unit_id;

  new.path_text = coalesce(parent_path || ' / ', '') || new.name;
  return new;
end;
$$;

drop trigger if exists trg_units_touch on public.units;
create trigger trg_units_touch before update on public.units
for each row execute procedure app.touch_updated_at();

drop trigger if exists trg_units_path on public.units;
create trigger trg_units_path before insert or update of parent_unit_id, name on public.units
for each row execute procedure app.touch_path_text();

drop trigger if exists trg_unit_memberships_touch on public.unit_memberships;
create trigger trg_unit_memberships_touch before update on public.unit_memberships
for each row execute procedure app.touch_updated_at();

drop trigger if exists trg_join_requests_touch on public.join_requests;
create trigger trg_join_requests_touch before update on public.join_requests
for each row execute procedure app.touch_updated_at();

create or replace function app.has_org_role(org_id uuid, allowed app.organization_role[])
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
      and coalesce(m.organization_role, case m.role
        when 'admin' then 'admin'::app.organization_role
        when 'manager' then 'admin'::app.organization_role
        else 'member'::app.organization_role
      end) = any (allowed)
  );
$$;

create or replace function app.has_unit_role(target_unit_id uuid, allowed app.unit_role[])
returns boolean
language sql
stable
as $$
  with recursive ancestors as (
    select u.id, u.parent_unit_id, 0 as depth
    from public.units u
    where u.id = target_unit_id
    union all
    select parent.id, parent.parent_unit_id, ancestors.depth + 1
    from public.units parent
    join ancestors on ancestors.parent_unit_id = parent.id
  )
  select exists (
    select 1
    from public.unit_memberships um
    join ancestors a on a.id = um.unit_id
    where um.user_id = app.current_user_id()
      and um.status = 'active'
      and (
        um.role = any (allowed)
        or (
          um.role = 'manager'
          and a.depth > 0
          and 'member'::app.unit_role = any (allowed)
        )
      )
  );
$$;

create or replace function app.can_read_folder(target_folder_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.folders f
    where f.id = target_folder_id
      and app.has_membership(f.organization_id)
      and (
        f.is_public = true
        or app.has_org_role(f.organization_id, array['owner', 'admin']::app.organization_role[])
        or (f.unit_id is not null and app.has_unit_role(f.unit_id, array['manager', 'member']::app.unit_role[]))
        or exists (
          select 1
          from public.folder_members fm
          where fm.folder_id = f.id
            and fm.user_id = app.current_user_id()
        )
      )
  );
$$;

create or replace function app.can_read_message(target_message_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.messages m
    where m.id = target_message_id
      and app.has_membership(m.organization_id)
      and (
        (
          m.message_scope = 'shared'
          and (
            m.folder_id is null
            or app.can_read_folder(m.folder_id)
            or (m.unit_id is not null and app.has_unit_role(m.unit_id, array['manager', 'member']::app.unit_role[]))
          )
        )
        or (
          m.message_scope = 'direct'
          and app.current_user_id() in (m.author_user_id, m.recipient_user_id)
        )
      )
  );
$$;

create or replace function app.can_post_message(
  org_id uuid,
  target_unit_id uuid,
  scope app.message_scope,
  target_recipient_user_id uuid default null
)
returns boolean
language sql
stable
as $$
  select
    app.has_membership(org_id)
    and (
      (
        scope = 'shared'
        and (
          target_unit_id is null
          or app.has_unit_role(target_unit_id, array['manager', 'member']::app.unit_role[])
          or app.has_org_role(org_id, array['owner', 'admin']::app.organization_role[])
        )
      )
      or (
        scope = 'direct'
        and target_recipient_user_id is not null
        and exists (
          select 1
          from public.memberships m
          where m.organization_id = org_id
            and m.user_id = target_recipient_user_id
            and m.status = 'active'
        )
      )
    );
$$;

alter table public.units enable row level security;
alter table public.unit_memberships enable row level security;
alter table public.organization_invites enable row level security;
alter table public.join_requests enable row level security;

drop policy if exists folders_read on public.folders;
create policy folders_read on public.folders
for select using (app.can_read_folder(id));

drop policy if exists folders_manager_write on public.folders;
create policy folders_manager_write on public.folders
for all using (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  or (unit_id is not null and app.has_unit_role(unit_id, array['manager']::app.unit_role[]))
)
with check (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  or (unit_id is not null and app.has_unit_role(unit_id, array['manager']::app.unit_role[]))
);

drop policy if exists tasks_read on public.tasks;
create policy tasks_read on public.tasks
for select using (
  app.has_membership(organization_id)
  and (
    unit_id is null
    or app.has_unit_role(unit_id, array['manager', 'member']::app.unit_role[])
    or app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  )
);

drop policy if exists tasks_write on public.tasks;
create policy tasks_write on public.tasks
for all using (
  app.has_membership(organization_id)
  and (
    unit_id is null
    or app.has_unit_role(unit_id, array['manager', 'member']::app.unit_role[])
    or app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  )
)
with check (
  app.has_membership(organization_id)
  and (
    unit_id is null
    or app.has_unit_role(unit_id, array['manager', 'member']::app.unit_role[])
    or app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  )
);

drop policy if exists messages_read on public.messages;
create policy messages_read on public.messages
for select using (app.can_read_message(id));

drop policy if exists messages_write on public.messages;
create policy messages_write on public.messages
for all using (app.can_post_message(organization_id, unit_id, message_scope, recipient_user_id))
with check (app.can_post_message(organization_id, unit_id, message_scope, recipient_user_id));

create policy units_read on public.units
for select using (app.has_membership(organization_id));

create policy units_write on public.units
for all using (app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[]))
with check (app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[]));

create policy unit_memberships_read on public.unit_memberships
for select using (
  exists (
    select 1
    from public.units u
    where u.id = unit_memberships.unit_id
      and app.has_membership(u.organization_id)
  )
);

create policy unit_memberships_write on public.unit_memberships
for all using (
  exists (
    select 1
    from public.units u
    where u.id = unit_memberships.unit_id
      and (
        app.has_org_role(u.organization_id, array['owner', 'admin']::app.organization_role[])
        or app.has_unit_role(u.id, array['manager']::app.unit_role[])
      )
  )
)
with check (
  exists (
    select 1
    from public.units u
    where u.id = unit_memberships.unit_id
      and (
        app.has_org_role(u.organization_id, array['owner', 'admin']::app.organization_role[])
        or app.has_unit_role(u.id, array['manager']::app.unit_role[])
      )
  )
);

create policy join_requests_read on public.join_requests
for select using (
  user_id = app.current_user_id()
  or app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
);

create policy join_requests_write on public.join_requests
for all using (
  user_id = app.current_user_id()
  or app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
)
with check (
  user_id = app.current_user_id()
  or app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
);

create policy organization_invites_read on public.organization_invites
for select using (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
);

create policy organization_invites_write on public.organization_invites
for all using (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
)
with check (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
);
