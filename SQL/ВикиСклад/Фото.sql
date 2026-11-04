create schema "Бирюлёвский дендропарк: ВикиСклад";

-- Отвечает долго
set http.curlopt_timeout_msec = 200000;

-- Получение данных без промежуточных утилит
create materialized view "Бирюлёвский дендропарк: ВикиСклад"."Wikimap" as
with c as (
	select urlencode('Biryulyovskiy_Arboretum') c
),
url as (
	select 'https://wikimap.toolforge.org/api.php?cat='
			|| c.c
			|| '&subcats&subcatdepth=8&camera=true&locator=true&allco=true' url
from c),
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
	select jsonb_array_elements(res.j) "json"
	  from res
),
geobaze as (
	select "json_table"."json" ->> 'pageid'::text AS pageid,
		   "json_table"."json" ->> 'title'::text AS title,
		   st_setsrid(st_point(
				((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'lon'::text)::double precision,
				((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'lat'::text)::double precision),
				4326
				) as "φλ₀",
		   ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'bearing'::text)::double precision AS "α₀",
		   ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'primary'::text)::boolean as "f₀",
		   ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'cam'::text) is not null as c,
		   st_setsrid(st_point(
				((("json_table"."json" -> 'coordinates'::text) -> 1) ->> 'lon'::text)::double precision,
				((("json_table"."json" -> 'coordinates'::text) -> 1) ->> 'lat'::text)::double precision),
				4326
				) as "φλ₁",
		   ((("json_table"."json" -> 'coordinates'::text) -> 1) ->> 'bearing'::text)::double precision AS "α₁",
		   ((("json_table"."json" -> 'coordinates'::text) -> 1) ->> 'primary'::text)::boolean AS "f₁",
		   "json_table"."json" ->> 'tag'::text AS tag,
		   "json_table"."json" ->> 'ns'::text AS ns,
		   "json_table"."json" -> 'coordinates'::text AS u,
		   "json_table"."json" -> 'imagedata'::text AS img,
		   'https://commons.wikimedia.org/wiki/'::text || ("json_table"."json" ->> 'title'::text) AS "URL"
	  from "json_table"
)
select pageid,
	   title,
	   "φλ₀", "α₀", "f₀",
	   c,
	   "φλ₁", "α₁", "f₁",
	   tag,
	   ns,
	   u,
	   img,
	   "URL",
	   st_collect(
			st_makeline("φλ₀", "φλ₁"),
			case
				WHEN "f₀" THEN "φλ₀"
				ELSE null::geometry
			end
			) "Vue"
 from geobaze;

comment on materialized view "Бирюлёвский дендропарк: ВикиСклад"."Wikimap" IS 'Все данные по точкам фотографий с ВикиСклада';

create view "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички" as
select w.*,
       (regexp_match(w.title, '(?<=^File\:Табличка «).+?(?=»)'))[1] AS "короткое название",
       (regexp_match(w.title, '(?<=на участке )\d+(?=[ \.])'))[1]::smallint AS "Уч. назв",
       coalesce(u₁."№", u₀."№") "Уч.",
       (regexp_match(w.title, '(?<=на участке )\d+(?=[ \.])'))[1]::smallint = coalesce(u₁."№", u₀."№") "участок по назв",
       u₀."№" AS "Уч.φλ₀",
       u₁."№" AS "Уч.φλ₁"
  from "Бирюлёвский дендропарк: ВикиСклад"."Wikimap" w
  left join "Бирюлёвский дендропарк: OSM"."Участки" u₀
    on st_intersects(u₀.geom, w."φλ₀")
  left join "Бирюлёвский дендропарк: OSM"."Участки" u₁
    on st_intersects(u₁.geom, w."φλ₁")
  where w.title ~ '^File\:Табличка'
  order by coalesce(u₁."№", u₀."№");

comment on view "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички" is 'Изображения видовых табличек с добавленеим сведений по участкам';

-- конец