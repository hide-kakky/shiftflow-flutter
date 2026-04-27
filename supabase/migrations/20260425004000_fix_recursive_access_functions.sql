create or replace function app.can_read_folder(target_folder_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, auth, app
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
security definer
set search_path = public, auth, app
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
security definer
set search_path = public, auth, app
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
