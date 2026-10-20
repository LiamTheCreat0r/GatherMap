-- Backfill coordinates for events created before the map-pinning feature.
--
-- These rows predate the `latitude`/`longitude` columns, so they carried only
-- a free-text `location`. Each is geocoded once here (via the MapTiler
-- geocoding API) and written back so the events can be pinned on the map.
--
-- Two of the location labels name fictional venues ("Club Mitte, Berlin",
-- "Bob's Place, Munich"); the geocoder can't resolve those, so they fall back
-- to their city's coordinates rather than a wrong-but-real match elsewhere.
update public.event set latitude = 52.45548717998874, longitude = 13.42885460704565 where id = 'e0000000-0000-0000-0000-000000000001'; -- Tempelhofer Feld, Berlin

update public.event set latitude = 52.517012076853675, longitude = 13.388821966946125 where id = 'e0000000-0000-0000-0000-000000000003'; -- Club Mitte -> Mitte, Berlin

update public.event set latitude = 48.13710811820439, longitude = 11.575382128357887 where id = 'e0000000-0000-0000-0000-000000000002'; -- Bob's Place -> Munich centre

update public.event set latitude = -23.55065065732485, longitude = -46.633382476866245 where id = '6e296468-cab8-4451-97b5-1393398501ee'; -- Sao Paulo

update public.event set latitude = 43.57395112252759, longitude = 1.459144502878189 where id = '458f4c4c-e221-4209-8a8c-7c36747cf5cc'; -- Rangueil, Toulouse
