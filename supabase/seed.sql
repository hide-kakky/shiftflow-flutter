insert into public.organizations (id, name, short_name, timezone, display_color)
values
  ('11111111-1111-1111-1111-111111111111', 'ShiftFlow Demo Org', 'SFD', 'Asia/Tokyo', '#517CB2')
on conflict (id) do nothing;

insert into public.users (id, email, display_name, language, theme, status, is_active)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin@shiftflow.local', 'Admin User', 'ja', 'system', 'active', true),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'manager@shiftflow.local', 'Manager User', 'ja', 'system', 'active', true),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'member@shiftflow.local', 'Member User', 'ja', 'system', 'active', true)
on conflict (id) do nothing;

insert into public.memberships (organization_id, user_id, role, status)
values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin', 'active'),
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'manager', 'active'),
  ('11111111-1111-1111-1111-111111111111', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'member', 'active')
on conflict (organization_id, user_id) do nothing;

insert into public.folders (id, organization_id, name, sort_order, color, is_active, is_public, is_system)
values
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', '11111111-1111-1111-1111-111111111111', 'Main', 0, '#517CB2', true, true, true)
on conflict (id) do nothing;

insert into public.tasks (organization_id, folder_id, title, description, status, priority, created_by_user_id)
values
  ('11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Open store', 'Prepare opening checklist', 'open', 'medium', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')
on conflict do nothing;

insert into public.messages (organization_id, folder_id, title, body, priority)
values
  ('11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'Daily memo', 'Check fridge temperature logs', 'medium')
on conflict do nothing;
