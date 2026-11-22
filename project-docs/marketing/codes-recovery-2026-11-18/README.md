# creator-codes.csv recovery (2026-11-18)

`ce.py reserve-codes 45` added 45 codes to the iMac pool (state/codes.tsv, now 265) and then crashed rewriting
creator-codes.csv (a malformed row with an extra column), truncating it to 43 rows. The file is gitignored; no backup.

Rebuild:
1. Download all 500 codes of ASC batch e6778bcd-7829-4431-aa72-c5f5ac6cfa55 (offer "Mahj+ Lifetime Creators 2026-10",
   dc18b396-..., on com.jackwallner.mahj.lifetime) with the ASC API (key in ~/.baseball_credentials).
2. creator/sent: the 43 kept rows here; every code in imac-codes-pool.tsv = "cold-email teacher pool (reserved
   2026-11-18)" (the last 45 also reserved 2026-11-18), with `to`/`day` as sent; wave 3 Nov 13 codes from
   ~/ios/growth/article-outreach-2026-11/wave-3-mahj/send-log.tsv; FYWL8N7JAAK7YR8AKN = "Jack link test (email to self)";
   TikTok creators from creator-affiliates-2026-10-29.md and the social logs. Anything else unknown: mark "unknown (lost
   2026-11-18)", never hand it out.
3. Fix cmd_reserve_codes before running it again: write to a temp file and replace, and use restval/extrasaction.
