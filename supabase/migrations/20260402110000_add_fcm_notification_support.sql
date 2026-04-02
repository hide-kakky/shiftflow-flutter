alter table public.notification_subscriptions
  add column if not exists provider text not null default 'webpush',
  add column if not exists device_token text;

alter table public.notification_subscriptions
  alter column endpoint drop not null,
  alter column p256dh drop not null,
  alter column auth drop not null;

create unique index if not exists idx_notification_subscriptions_fcm_unique
  on public.notification_subscriptions(user_id, provider, device_token)
  where device_token is not null;
