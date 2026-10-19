-- Mahj 1.4.2: each day's round is the Mahj Minute, five questions instead of
-- three. The score check and the baseline players scale with it.
--
-- Baseline scores so every player gets a standing from day one of a month.
-- Fifty placeholder players, rebuilt from the clock on every call (never
-- stored): each plays a fixed share of the days so far at a fixed accuracy,
-- best 20 days, five questions a day. A real daily player near perfect lands
-- near the top; a one-day player mid-month lands in the bottom half (no rank
-- shown). Once real players number in the thousands the baseline is noise.
create or replace function public.challenge_baseline(p_month text)
returns table (points int)
language sql
stable
set search_path = public
as $$
  with d as (
    select greatest(1, least(31,
      floor(extract(epoch from now() - to_date(p_month || '-01', 'YYYY-MM-DD')) / 86400)::int + 1
    )) as elapsed
  ), g as (
    select i,
           0.15 + 0.8 * ((i * 0.618034) - floor(i * 0.618034)) as attendance,
           0.5 + 0.45 * i / 49.0 as accuracy
      from generate_series(0, 49) as i
  )
  select round(g.accuracy * 5 * least(round(g.attendance * d.elapsed), 20))::int
    from g, d
   where round(g.attendance * d.elapsed) >= 1;
$$;

revoke all on function public.challenge_baseline(text) from public, anon, authenticated;

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
  v_base_players int;
  v_base_below int;
begin
  if p_app !~ '^[a-z]{2,20}$' or p_month !~ '^[0-9]{4}-[0-9]{2}$' then
    raise exception 'bad input';
  end if;
  -- Five questions a day, best 20 days.
  if p_days < 1 or p_days > 31 or p_points < 0 or p_points > 5 * least(p_days, 20) then
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

  select count(*), count(*) filter (where b.points < v_points)
    into v_base_players, v_base_below
    from challenge_baseline(p_month) as b;

  return json_build_object('players', v_players + v_base_players, 'below', v_below + v_base_below);
end;
$$;

revoke all on function public.challenge_submit(text, text, uuid, int, int) from public;
grant execute on function public.challenge_submit(text, text, uuid, int, int) to anon;
