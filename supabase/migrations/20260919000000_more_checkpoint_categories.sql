-- The pilot grew from twelve landmarks to the city's parks, markets, malls,
-- places to eat, photo spots and stages (content/checkpoints.json,
-- 2026-09-19). Five new categories; the client falls back to `street` for any
-- value it does not know, so an older build keeps working.
--
-- `add value` cannot run inside a transaction block on older Postgres; each is
-- its own statement, and `if not exists` makes the migration re-runnable.
alter type public.checkpoint_category add value if not exists 'park';
alter type public.checkpoint_category add value if not exists 'shopping';
alter type public.checkpoint_category add value if not exists 'food';
alter type public.checkpoint_category add value if not exists 'sight';
alter type public.checkpoint_category add value if not exists 'entertainment';
