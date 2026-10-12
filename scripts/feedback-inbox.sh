#!/bin/bash
# Prints unread Mahj feedback rows and marks them read.
# Needs SUPABASE_ACCESS_TOKEN (the Supabase CLI login) in the environment.
#   scripts/feedback-inbox.sh          # unread only, then mark read
#   scripts/feedback-inbox.sh --all    # everything, no marking
set -e
: "${SUPABASE_ACCESS_TOKEN:?set SUPABASE_ACCESS_TOKEN (supabase login)}"
REF=ucoveqbyfuxqvpysmixu
if [ "$1" = "--all" ]; then
  WHERE="app = 'mahj'"
  MARK=0
else
  WHERE="app = 'mahj' and read_at is null"
  MARK=1
fi
SQL="select id, created_at, kind, is_member, app_version, device, message, context from public.app_feedback where $WHERE order by created_at desc limit 200"
python3 -I - "$SUPABASE_ACCESS_TOKEN" "$REF" "$SQL" "$MARK" <<'PY'
import json, sys, urllib.request
tok, ref, sql, mark = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4] == "1"
def q(s):
    req = urllib.request.Request(f"https://api.supabase.com/v1/projects/{ref}/database/query",
        data=json.dumps({"query": s}).encode(),
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "application/json"}, method="POST")
    return json.loads(urllib.request.urlopen(req).read().decode())
rows = q(sql)
if not rows:
    print("No feedback."); sys.exit(0)
for r in rows:
    member = "member" if r["is_member"] else "free"
    print(f"{r['created_at'][:16]}  {r['kind']:<12} {member:<6} {r['app_version'] or ''} {r['device'] or ''}")
    print(f"  {r['message']}")
    ctx = r.get("context") or {}
    if ctx: print("  " + ", ".join(f"{k}={v}" for k, v in ctx.items()))
    print()
print(f"{len(rows)} row(s).")
if mark:
    ids = ",".join(f"'{r['id']}'" for r in rows)
    q(f"update public.app_feedback set read_at = now() where id in ({ids})")
PY
