-- Meta StartTrial relay: retry transient failures instead of dropping the
-- trial. A network error, 429 or 5xx from RevenueCat or Meta keeps the row
-- pending, counts it in `attempts` and holds it until `retry_at`.

alter table public.meta_trial_relay
  add column if not exists attempts integer not null default 0,
  add column if not exists retry_at timestamptz;

-- Same as before, plus: a trial backing off does not wake the function.
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
      and (retry_at is null or retry_at <= now())
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
