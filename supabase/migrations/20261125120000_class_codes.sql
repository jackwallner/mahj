-- Class codes (Mahj 1.4.7). A teacher's students type or scan one code; Home
-- then shows the class name and the room the teacher wants this week. Jack
-- edits `classes` by hand (the dashboard or SQL); there is no teacher login.
-- Players never read the tables. class_fetch answers one code at a time and
-- records a random per-install token, so Jack can count joins and weekly
-- activity per class without anything that identifies a player.
create table if not exists public.classes (
  app text not null,
  code text not null,
  name text not null,
  focus_room text not null,
  active boolean not null default true,
  updated_at timestamptz not null default now(),
  primary key (app, code),
  constraint classes_code_shape check (code ~ '^[A-Z0-9]{4,12}$'),
  constraint classes_name_length check (char_length(name) between 1 and 40),
  constraint classes_focus_room check (
    focus_room in ('tile-room', 'card-room', 'charleston-room', 'table-room', 'pro-tables')
  )
);

create table if not exists public.class_members (
  app text not null,
  code text not null,
  player uuid not null,
  joined_at timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  primary key (app, code, player),
  foreign key (app, code) references public.classes (app, code) on delete cascade
);

alter table public.classes enable row level security;
alter table public.class_members enable row level security;
-- No policies: only the security definer function below touches the tables.
revoke all on public.classes from anon, authenticated;
revoke all on public.class_members from anon, authenticated;

create or replace function public.class_fetch(p_app text, p_code text, p_player uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_class classes%rowtype;
begin
  if p_app !~ '^[a-z]{2,20}$' or p_code !~ '^[A-Z0-9]{4,12}$' then
    return null;
  end if;

  select * into v_class from classes where app = p_app and code = p_code and active;
  if not found then
    return null;
  end if;

  insert into class_members as m (app, code, player)
  values (p_app, p_code, p_player)
  on conflict (app, code, player) do update set last_seen = now();

  return json_build_object('name', v_class.name, 'focus_room', v_class.focus_room);
end;
$$;

revoke all on function public.class_fetch(text, text, uuid) from public;
grant execute on function public.class_fetch(text, text, uuid) to anon;
