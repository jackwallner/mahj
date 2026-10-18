-- Monthly challenge standings (Mahj 1.4.1). One row per app, month and
-- random per-month token: no account, device id or anything identifying.
-- Players never read the table; challenge_submit records a score and answers
-- with how many players there are and how many are below it.
create table if not exists public.challenge_scores (
  app text not null,
  month_key text not null,
  player uuid not null,
  points int not null,
  days int not null,
  updated_at timestamptz not null default now(),
  primary key (app, month_key, player)
);

alter table public.challenge_scores enable row level security;
-- No policies: only the security definer function below touches the table.
revoke all on public.challenge_scores from anon, authenticated;

create index if not exists challenge_scores_month_points
  on public.challenge_scores (app, month_key, points);

create or replace function public.challenge_submit(
  p_app text, p_month text, p_player uuid, p_points int, p_days int
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_points int;
  v_players int;
  v_below int;
begin
  if p_app !~ '^[a-z]{2,20}$' or p_month !~ '^[0-9]{4}-[0-9]{2}$' then
    raise exception 'bad input';
  end if;
  -- Three questions a day, best 20 days.
  if p_days < 1 or p_days > 31 or p_points < 0 or p_points > 3 * least(p_days, 20) then
    raise exception 'bad score';
  end if;
  -- Only the month that is running somewhere on Earth right now.
  if p_month not in (to_char(now() - interval '14 hours', 'YYYY-MM'), to_char(now() + interval '14 hours', 'YYYY-MM')) then
    raise exception 'closed month';
  end if;

  insert into challenge_scores as c (app, month_key, player, points, days)
  values (p_app, p_month, p_player, p_points, p_days)
  on conflict (app, month_key, player) do update
    set points = greatest(c.points, excluded.points),
        days = greatest(c.days, excluded.days),
        updated_at = now()
  returning points into v_points;

  select count(*), count(*) filter (where points < v_points)
    into v_players, v_below
    from challenge_scores
   where app = p_app and month_key = p_month;

  return json_build_object('players', v_players, 'below', v_below);
end;
$$;

revoke all on function public.challenge_submit(text, text, uuid, int, int) from public;
grant execute on function public.challenge_submit(text, text, uuid, int, int) to anon;
