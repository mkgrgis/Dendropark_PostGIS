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

CREATE TABLE "Бирюлёвский дендропарк"."∀ WikiMap" (
	r jsonb NOT NULL,
	t timestamptz(0) NOT NULL DEFAULT now(),
	CONSTRAINT "WikiMap_Павловский_парк_pk" PRIMARY KEY (t)
);
COMMENT ON TABLE "Бирюлёвский дендропарк"."∀ WikiMap" IS 'Данные импорта JSON из карты изображений ВикиСклада в единственную строку.';

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

CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк"."WikiMap ∀"
TABLESPACE pg_default
AS WITH json_table AS (
		 SELECT jsonb_array_elements("wmпп".r) AS json
		   FROM "Бирюлёвский дендропарк"."∀ WikiMap" "wmпп"
		), geobaze AS (
		 SELECT json_table.json ->> 'pageid'::text AS pageid,
			json_table.json ->> 'title'::text AS title,
			st_setsrid(st_point((((json_table.json -> 'coordinates'::text) -> 0) ->> 'lon'::text)::double precision, (((json_table.json -> 'coordinates'::text) -> 0) ->> 'lat'::text)::double precision), 4326) AS "φλ₀",
			(((json_table.json -> 'coordinates'::text) -> 0) ->> 'bearing'::text)::double precision AS "α₀",
			(((json_table.json -> 'coordinates'::text) -> 0) ->> 'primary'::text)::boolean AS "f₀",
			(((json_table.json -> 'coordinates'::text) -> 0) ->> 'cam'::text) IS NOT NULL AS c,
			st_setsrid(st_point((((json_table.json -> 'coordinates'::text) -> 1) ->> 'lon'::text)::double precision, (((json_table.json -> 'coordinates'::text) -> 1) ->> 'lat'::text)::double precision), 4326) AS "φλ₁",
			(((json_table.json -> 'coordinates'::text) -> 1) ->> 'bearing'::text)::double precision AS "α₁",
			(((json_table.json -> 'coordinates'::text) -> 1) ->> 'primary'::text)::boolean AS "f₁",
			json_table.json ->> 'tag'::text AS tag,
			json_table.json ->> 'ns'::text AS ns,
			json_table.json -> 'coordinates'::text AS u,
			json_table.json -> 'imagedata'::text AS img,
			'https://commons.wikimedia.org/wiki/' || (json_table.json ->> 'title'::text) AS "URL"
		   FROM json_table
		)
 SELECT geobaze.*,	
		st_collect(st_makeline(geobaze."φλ₀", geobaze."φλ₁"),
		CASE
			WHEN geobaze."f₀" THEN geobaze."φλ₀"
			ELSE NULL::geometry
		END) AS "Vue"
   FROM geobaze
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Бирюлёвский дендропарк"."WikiMap ∀" IS 'Все данные по точкам с ВикиСклада';

CREATE TABLE "Бирюлёвский дендропарк"."∀ PastVu" (
	r jsonb NOT NULL,
	t timestamptz(0) NOT NULL DEFAULT now(),
	"isPainting" bool NOT NULL,
	CONSTRAINT "PastVu_Павловский_парк_pk" PRIMARY KEY (t)
);

CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк"."PastVu ∀"
TABLESPACE pg_default
AS
WITH json_table AS (
	 SELECT jsonb_array_elements(p.r -> 'result' ->'photos') AS json,
			p."isPainting"
	   FROM "Бирюлёвский дендропарк"."∀ PastVu" p
), geobaze AS (
	select json_table.json ->> 'cid' "№",
		   json_table.json ->> 'title' "Название",
		   json_table.json ->> 'dir' "dir",
		   st_setsrid(
		   	st_point(((json_table.json -> 'geo') ->> 1)::double precision,
		   			((json_table.json -> 'geo') ->> 0)::double precision), 4326) "φλ₀",
		   --json_table.json ->> 'geo' "",
		   'https://pastvu.com/_p/a/' || (json_table.json ->> 'file') "URL",
		   json_table.json ->> '__v' "v",
		   json_table.json ->> 'year' "от",
		   json_table.json ->> 'year2' "до",
		   "isPainting",
		   json_table.json - 'year2' - 'year' - '__v' - 'file' - 'geo' - 'dir' - 'title' - 'cid'  "json"
	  FROM json_table
)
select * from geobaze
WITH DATA;

-- Исторические фотографии в границах парка
CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк"."PastVu парк ∀"
TABLESPACE pg_default
as
SELECT p.*,
	   st_intersection("ог".geom, p."φλ₀") AS geom,
	   st_geometrytype(st_intersection("ог".geom, p."φλ₀")) AS geom_type
  FROM "Бирюлёвский дендропарк"."PastVu ∀" p
  JOIN "Бирюлёвский дендропарк"."Основная граница" "ог"
	ON st_contains("ог".geom, p."φλ₀")	 
  WITH DATA;
