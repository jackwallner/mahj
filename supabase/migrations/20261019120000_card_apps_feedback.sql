-- The four card trainers (Bridge, Skat, Cribbage, Sheepshead) send feedback
-- to the same insert-only table as Mahj, under their own app id.
alter policy "mahj anon insert" on public.app_feedback
  with check (
    app = any (array['mahj', 'bridge', 'skat', 'cribbage', 'sheepshead'])
    and kind = any (array['general', 'not_enjoying', 'question', 'churn'])
  );
