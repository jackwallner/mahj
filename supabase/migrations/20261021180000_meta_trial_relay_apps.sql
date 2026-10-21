-- One relay for Mahj and the four card trainers: each trial row names its
-- app (the webhook's ?app=, Mahj when absent). Apply before deploying the
-- function, which selects and writes the column.
alter table public.meta_trial_relay
  add column if not exists app text not null default 'mahj';

create index if not exists meta_trial_relay_app on public.meta_trial_relay (app, status);
