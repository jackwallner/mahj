-- Read access for the ops morning digest (~/ios/ops), which reports each
-- day's player feedback across the apps that write app_feedback. The digest
-- calls this with the publishable key plus its own secret (OPS_FEEDBACK_KEY in
-- the Pro's ~/.ops_credentials); only that secret's SHA-256 is stored here.
-- It returns no ids, devices or locales, and it never marks rows read, so
-- scripts/feedback-inbox.sh still sees them as unread.
create or replace function public.ops_feedback_read(
  p_key text, p_since timestamptz, p_until timestamptz
) returns table (
  created_at timestamptz, app text, kind text, is_member boolean,
  app_version text, message text, moment text
)
language plpgsql
security definer
set search_path = ''
as $$
begin
  if encode(pg_catalog.sha256(convert_to(coalesce(p_key, ''), 'UTF8')), 'hex')
     <> '16bad1a89b8dc8745a8ee9812a0e8dba19c28e320bfb7aaf2e87d2783f4ca223' then
    raise exception 'not allowed';
  end if;
  if p_until <= p_since or p_until - p_since > interval '8 days' then
    raise exception 'bad window';
  end if;
  return query
    select f.created_at, f.app, f.kind, f.is_member, f.app_version, f.message,
           f.context ->> 'moment'
    from public.app_feedback f
    where f.created_at >= p_since and f.created_at < p_until
    order by f.created_at;
end;
$$;

revoke all on function public.ops_feedback_read(text, timestamptz, timestamptz) from public, authenticated;
grant execute on function public.ops_feedback_read(text, timestamptz, timestamptz) to anon;
