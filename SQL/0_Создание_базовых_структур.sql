-- Все объекты будут размещены в специальной схеме
CREATE SCHEMA "Бирюлёвский дендропарк";

CREATE TABLE "Бирюлёвский дендропарк"."∀ osmium" (
	geom geometry NULL,
	osm_type varchar(8) NULL,
	osm_id int8 NULL,
	"version" int4 NULL,
	changeset int4 NULL,
	uid int4 NULL,
	"user" varchar(256) NULL,
	"timestamp" timestamptz(0) NULL,
	way_nodes _int8 NULL,
	tags jsonb NULL
);
COMMENT ON TABLE "Бирюлёвский дендропарк"."∀ osmium" IS 'Таблица для Osmium импорта данных, покрывающих Бирюлёвский дендропарк. Данные впоследствии фильтруюется по границам парка.';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Основная граница"
AS SELECT "oпп".tags ->> 'name'::text AS "Название",
	"oпп".tags ->> 'operator'::text AS "Оператор",
	"oпп".osm_id,
	"oпп".geom
FROM "Бирюлёвский дендропарк"."∀ osmium" "oпп"
WHERE ("oпп".tags ->> 'leisure'::text) = 'park'::text AND ("oпп".tags ->> 'name'::text) = 'Бирюлёвский дендропарк'::text;

COMMENT ON VIEW "Бирюлёвский дендропарк"."Основная граница" IS 'Фильтр, выделяющий из данных, содержащих Бирюлёвский дендропарк его границу.';


CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк"."OSM ∀"
TABLESPACE pg_default
AS SELECT "oпп".osm_id,
	"oпп".osm_type,
	"oпп".tags,
	st_intersection("ог".geom, "oпп".geom) AS geom,
	st_geometrytype(st_intersection("ог".geom, "oпп".geom)) geom_type
	FROM "Бирюлёвский дендропарк"."∀ osmium" "oпп"
	JOIN "Бирюлёвский дендропарк"."Основная граница" "ог" ON st_intersects("ог".geom, "oпп".geom)
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Бирюлёвский дендропарк"."OSM ∀" IS 'Все данные, относящиеся к Бирюлёвскому дендропарку включая данные на его границах.';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Участки"
AS SELECT osm_id,
		osm_type,
		(tags ->> 'name'::text)::smallint AS "№",
		tags ->> 'description'::text AS "Описание",
		geom
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
  WHERE (tags ->> 'boundary'::text) = 'forest_compartment'::text AND (tags ->> 'name'::text) ~ '^\d+(\.\d+)?$'::text
  ORDER BY ((tags ->> 'name'::text)::smallint);
COMMENT ON VIEW "Бирюлёвский дендропарк"."Участки" IS 'Участки дендропарка по лесотехнической БД. Общая граница исключена из выборки.';

SET http.curlopt_timeout_msec = 200000;
-- Получение данных без промежуточных утилит
create materialized view "Бирюлёвский дендропарк"."Wikimap curl" as
with c as (select urlencode('Biryulyovskiy_Arboretum') c),
url as (
select 'https://wikimap.toolforge.org/api.php?cat='
|| c.c
|| '&subcats&subcatdepth=8&camera=true&locator=true&allco=true' url
from c),
rq as (
select http_get(url.url) t,
 url.url from url
),
res as (
select ((t).content)::jsonb j from rq ),
json_table as (
select jsonb_array_elements(res.j) "json" from res
),
geobaze as (
     select "json_table"."json" ->> 'pageid'::text AS pageid,
            "json_table"."json" ->> 'title'::text AS title,
            st_setsrid(st_point(((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'lon'::text)::double precision, ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'lat'::text)::double precision), 4326) as "φλ₀",
            ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'bearing'::text)::double precision AS "α₀",
            ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'primary'::text)::boolean as "f₀",
            ((("json_table"."json" -> 'coordinates'::text) -> 0) ->> 'cam'::text) is not null as c,
            st_setsrid(st_point(((("json_table"."json" -> 'coordinates'::text) -> 1) ->> 'lon'::text)::double precision, ((("json_table"."json" -> 'coordinates'::text) -> 1) ->> 'lat'::text)::double precision), 4326) as "φλ₁",
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
        "φλ₀",
        "α₀",
        "f₀",
        c,
        "φλ₁",
        "α₁",
        "f₁",
        tag,
        ns,
        u,
        img,
        "URL",
        st_collect(st_makeline("φλ₀", "φλ₁"),
        case
            WHEN "f₀" THEN "φλ₀"
            ELSE NULL::geometry
        END) AS "Vue"
    FROM geobaze;

create materialized view "Бирюлёвский дендропарк"."PastVu ∀ curl" as
with c as (
select '[[[37.6702389,55.5878667],[37.685957,55.5878667],[37.685957,55.6067487],[37.6702389,55.6067487],[37.6702389,55.5878667]]]' as q,
false as paint),
url as (
select 'https://pastvu.com/api2?method=photo.getByBounds&params=%7B%22z%22:18,%22localWork%22:true,%22isPainting%22:' 
|| c.paint || ',%22geometry%22:%7B%22type%22:%22Polygon%22,%22coordinates%22:'
|| c.q
|| '%7D%7D' url
from c),
rq as (
select http_get(url.url) t,
 url.url from url
),
res as (
select ((t).content)::jsonb j from rq ),
json_table as (
select jsonb_array_elements(res.j->'result'->'photos') "JSON" from res
)
select 
    (a."JSON" ->> 'cid'::text)::integer AS cid,
    a."JSON" ->> 'dir'::text AS dir,
    to_date(a."JSON" ->> 'year'::text, 'YYYY'::text) AS "t⇤",
    to_date(a."JSON" ->> 'year2'::text, 'YYYY'::text) AS "t⇥",
    st_setsrid(st_point(((a."JSON" -> 'geo'::text) ->> 1)::double precision, ((a."JSON" -> 'geo'::text) ->> 0)::double precision), 4326) AS "φλ₀",
    a."JSON" ->> 'file'::text AS "imgURL",
    a."JSON" ->> 'title'::text AS title,
    a."JSON" ->> 'source'::text AS source
 from json_table a;

COMMENT ON MATERIALIZED VIEW "Бирюлёвский дендропарк"."WikiMap ∀ curl" IS 'Все данные по точкам с ВикиСклада';

-- Исторические фотографии в границах парка
CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк"."PastVu парк ∀"
TABLESPACE pg_default
as
SELECT p.*,
	   st_intersection("ог".geom, p."φλ₀") AS geom,
	   st_geometrytype(st_intersection("ог".geom, p."φλ₀")) AS geom_type
  FROM "Бирюлёвский дендропарк"."PastVu ∀ curl" p
  JOIN "Бирюлёвский дендропарк"."Основная граница" "ог"
	ON st_contains("ог".geom, p."φλ₀")	 
  WITH DATA;

-- Убедиться что данные заполнились!
select ST_Area(ST_Transform(geom, 26986)) / 10000.0 "Площадь в га"
from "Бирюлёвский дендропарк"."Основная граница";