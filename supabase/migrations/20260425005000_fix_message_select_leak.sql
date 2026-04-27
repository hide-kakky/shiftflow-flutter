drop policy if exists messages_write on public.messages;
drop policy if exists messages_insert on public.messages;

create policy messages_insert on public.messages
for insert with check (
  app.can_post_message(organization_id, unit_id, message_scope, recipient_user_id)
);
