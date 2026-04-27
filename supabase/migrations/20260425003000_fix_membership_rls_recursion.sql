create or replace function app.has_membership(org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app
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
security definer
set search_path = public, auth, app
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

create or replace function app.has_org_role(org_id uuid, allowed app.organization_role[])
returns boolean
language sql
stable
security definer
set search_path = public, auth, app
as $$
  select exists (
    select 1
    from public.memberships m
    where m.organization_id = org_id
      and m.user_id = app.current_user_id()
      and m.status = 'active'
      and coalesce(
        m.organization_role,
        case m.role
          when 'admin' then 'admin'::app.organization_role
          when 'manager' then 'admin'::app.organization_role
          else 'member'::app.organization_role
        end
      ) = any (allowed)
  );
$$;

create or replace function app.has_unit_role(target_unit_id uuid, allowed app.unit_role[])
returns boolean
language sql
stable
security definer
set search_path = public, auth, app
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

drop policy if exists membership_read on public.memberships;
create policy membership_read on public.memberships
for select using (app.has_membership(organization_id));

drop policy if exists membership_admin_write on public.memberships;
create policy membership_admin_write on public.memberships
for all using (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  or app.has_role(organization_id, array['admin', 'manager']::app.user_role[])
)
with check (
  app.has_org_role(organization_id, array['owner', 'admin']::app.organization_role[])
  or app.has_role(organization_id, array['admin', 'manager']::app.user_role[])
);
