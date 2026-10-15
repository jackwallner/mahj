-- Meta StartTrial relay (supabase/functions/meta-trial-relay). Lives in the
-- shared "Sports" project next to app_feedback. See project-docs/marketing/meta-ads.md.

create table if not exists public.meta_trial_relay (
  id text primary key,                 -- RevenueCat webhook event id
  app_user_id text not null,
  original_transaction_id text,
  transaction_id text,
  product_id text,
  store text,
  environment text,
  trial_started_at timestamptz not null,
  received_at timestamptz not null default now(),
  -- pending | sent | would_send | cancelled | no_consent | error
  status text not null default 'pending',
  detail text,
  cancelled_at timestamptz,
  checked_at timestamptz,
  sent_at timestamptz,
  meta_response jsonb
);

create index if not exists meta_trial_relay_due
  on public.meta_trial_relay (trial_started_at) where status = 'pending';
create index if not exists meta_trial_relay_txn
  on public.meta_trial_relay (original_transaction_id);

-- Service role only: no policies, so anon and authenticated see nothing.
alter table public.meta_trial_relay enable row level security;

-- Calls the sweep only when a trial is due, so an idle relay costs no
-- function invocations. Needs vault secrets meta_relay_url and
-- meta_relay_cron_secret.
create or replace function public.meta_trial_relay_tick()
returns bigint
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $$
declare
  fn_url text := (select decrypted_secret from vault.decrypted_secrets where name = 'meta_relay_url');
  secret text := (select decrypted_secret from vault.decrypted_secrets where name = 'meta_relay_cron_secret');
begin
  if fn_url is null or secret is null then
    return null;
  end if;
  if not exists (
    select 1 from public.meta_trial_relay
    where status = 'pending' and trial_started_at <= now() - interval '15 minutes'
  ) then
    return null;
  end if;
  return net.http_post(
    url := fn_url || '?sweep',
    headers := jsonb_build_object('content-type', 'application/json', 'x-cron-secret', secret),
    body := '{}'::jsonb,
    timeout_milliseconds := 60000
  );
end;
$$;

revoke all on function public.meta_trial_relay_tick() from public, anon, authenticated;

select cron.unschedule('meta-trial-relay')
  where exists (select 1 from cron.job where jobname = 'meta-trial-relay');
select cron.schedule('meta-trial-relay', '* * * * *', 'select public.meta_trial_relay_tick()');
