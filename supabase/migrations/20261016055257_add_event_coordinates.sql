-- Add map coordinates to events so they can be pinned on the map.
--
-- Nullable on purpose: rows created before this migration have no stored
-- position, and free-typed (non-geocoded) locations have none either. The
-- map simply skips events whose coordinates are null.
alter table public.event
  add column latitude double precision,
  add column longitude double precision;
