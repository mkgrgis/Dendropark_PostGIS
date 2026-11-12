create schema "Бирюлёвский дендропарк: PastVu";

-- Скачка всего в окрестностях
create or replace view "Бирюлёвский дендропарк: PastVu"."∀ curl" as
with c as (
	select '[[[37.6702389,55.5878667],[37.685957,55.5878667],[37.685957,55.6067487],[37.6702389,55.6067487],[37.6702389,55.5878667]]]' as q,
	false as paint
),
url as (
	select 'https://pastvu.com/api2?method=photo.getByBounds&params=%7B%22z%22:18,%22localWork%22:true,%22isPainting%22:'
			|| c.paint || ',%22geometry%22:%7B%22type%22:%22Polygon%22,%22coordinates%22:'
			|| c.q
			|| '%7D%7D' url
	  from c
),
rq as (
	select http_get(url.url) t,
		   url.url
	  from url
),
res as (
	select ((t).content)::jsonb j
	  from rq
),
json_table as (
	select jsonb_array_elements(res.j->'result'->'photos') "JSON"
	  from res
)
select (a."JSON" ->> 'cid'::text)::integer AS cid,
	   a."JSON" ->> 'dir'::text AS dir,
	   to_date(a."JSON" ->> 'year'::text, 'YYYY'::text) AS "t⇤",
	   to_date(a."JSON" ->> 'year2'::text, 'YYYY'::text) AS "t⇥",
	   st_setsrid(st_point(
			((a."JSON" -> 'geo'::text) ->> 1)::double precision,
			((a."JSON" -> 'geo'::text) ->> 0)::double precision),
			4326
			) AS "φλ₀",
	   a."JSON" ->> 'file'::text AS "imgURL",
	   a."JSON" ->> 'title'::text AS title,
	   a."JSON" ->> 'source'::text AS source
  from json_table a;

-- Может отвечать долго, хотя обычно в 5 секунд укладывается с запасом
set http.curlopt_timeout_msec = 20000;

-- Исторические фотографии в границах парка
create materialized view "Бирюлёвский дендропарк: PastVu"."PastVu парк ∀"
tablespace pg_default
as
select p.*,
	   st_intersection("ог".geom, p."φλ₀") AS geom,
	   st_geometrytype(st_intersection("ог".geom, p."φλ₀")) AS geom_type
  from "Бирюлёвский дендропарк: PastVu"."∀ curl" p
  join "Бирюлёвский дендропарк: OSM"."Основная граница" "ог"
	on st_contains("ог".geom, p."φλ₀")
  with data;

-- конец