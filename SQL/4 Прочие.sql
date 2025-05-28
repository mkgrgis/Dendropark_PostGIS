-- "Бирюлёвский дендропарк"."ДТС" исходный текст

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."ДТС"
AS SELECT
        CASE
            WHEN geometrytype(geom) = 'POLYGON'::text THEN st_exteriorring(geom)
            ELSE geom
        END AS geom,
    "Название",
    round(st_length(
        CASE
            WHEN geometrytype(geom) = 'POLYGON'::text THEN st_exteriorring(geom)
            ELSE geom
        END::geography)::numeric, 1) AS l,
    st_asgeojson(geom) AS "GeoJSON"
   FROM "Бирюлёвский дендропарк"."ДТС 0" "д"
  ORDER BY "Название";


-- "Бирюлёвский дендропарк"."ДТС 0" исходный текст

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."ДТС 0"
AS SELECT st_union(geom) AS geom,
    tags ->> 'name'::text AS "Название"
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
  WHERE (tags ->> 'highway'::text) IS NOT NULL
  GROUP BY (tags ->> 'name'::text);
-- "Бирюлёвский дендропарк"."Дороги" source

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Дороги"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'highway'::text AS highway,
    a.tags ->> 'surface'::text AS surface,
    a.tags ->> 'width'::text AS width,
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL AND (a.tags ->> 'highway'::text) <> 'street_lamp'::text AND (a.tags ->> 'highway'::text) <> 'steps'::text;


-- "Бирюлёвский дендропарк"."Здания" source

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Здания"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'building'::text AS building,
    a.tags ->> 'height'::text AS height,
    st_area(a.geom) AS "площадь",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'building'::text - 'name'::text - 'height'::text - 'note'::text - 'description'::text AS tags
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
  WHERE (a.tags ->> 'building'::text) IS NOT NULL;


-- "Бирюлёвский дендропарк"."Лестницы" source

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Лестницы"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'highway'::text AS highway,
    a.tags ->> 'surface'::text AS surface,
    a.tags ->> 'width'::text AS width,
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL AND (a.tags ->> 'highway'::text) = 'steps'::text;


-- "Бирюлёвский дендропарк"."Мосты" source

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Мосты"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    st_area(a.geom) AS "площадь",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags ->> 'start_date'::text AS "Построено",
    a.tags ->> 'bridge:structure'::text AS "Структура",
    a.tags - 'name'::text - 'note'::text - 'description'::text - 'man_made'::text - 'start_date'::text AS tags,
    a.tags ->> 'layer'::text AS l
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
  WHERE (a.tags ->> 'man_made'::text) = 'bridge'::text;

----- Геометрические объекты
create view "Бирюлёвский дендропарк"."OSM geom маточные площадки" as
select  m.*,
		a.osm_id,
	    a.osm_type,
	    a.geom,
        st_area(a.geom) AS "площадь"
--	    a.tags,
   from "Бирюлёвский дендропарк"."OSM ∀" a 
   left join "Бирюлёвский дендропарк"."Участки" u ON st_intersects(u.geom, a.geom)
   left join "Бирюлёвский дендропарк"."№ площадок по ОСМ" m
     on m."Уч." =  u."№"
    and m."Код" = a.tags ->> 'ref'
   where (a.tags ->> 'ref'::text) is not null
     and ((a.tags ->> 'barrier') is null or (a.tags ->> 'barrier'::text) <> 'gate'::text)
     and (((a.tags ->> 'natural'::text) = any (array['wood'::text, 'scrub'::text, 'tree_row'::text, 'tree'::text])) or (a.tags ->> 'barrier'::text) = 'hedge'::text)
order by "Уч.", №, "Код";

-- Геометрия кучей и с дублированием
/*
CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Маточные площадки"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    u."№" AS "Уч.",
    (regexp_matches(a.tags ->> 'ref'::text, '\d+'::text))[1]::smallint AS "№",
    (a.tags ->> 'ref'::text) ~ '\*'::text AS "неоф",
    regexp_replace(a.tags ->> 'ref'::text, '\d+\*?\;?'::text, ''::text) AS "литер",
    to_date(a.tags ->> 'ref:start_date'::text, 'YYYY'::text) AS "год учёта",
    (string_to_array(a.tags ->> 'taxon'::text, ';'::text))[1] AS taxon,
    (string_to_array(a.tags ->> 'taxon:ru'::text, ';'::text))[1] AS "вид",
    (string_to_array(a.tags ->> 'genus'::text, ';'::text))[1] AS genus,
    (string_to_array(a.tags ->> 'genus:ru'::text, ';'::text))[1] AS "род",
    (string_to_array(a.tags ->> 'taxon'::text, ';'::text))[2] AS "taxon+",
    (string_to_array(a.tags ->> 'taxon:ru'::text, ';'::text))[2] AS "вид+",
    (string_to_array(a.tags ->> 'genus'::text, ';'::text))[2] AS "genus+",
    (string_to_array(a.tags ->> 'genus:ru'::text, ';'::text))[2] AS "род+",
    a.tags ->> 'source:taxon'::text AS "подтв вида",
    a.tags ->> 'natural'::text AS "тип посадки",
    a.tags ->> 'leaf_cycle'::text AS "листопадность",
    a.tags ->> 'leaf_type'::text AS "листва",
    st_area(a.geom) AS "площадь",
    a.tags ->> 'start_date'::text AS "создано",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags ->> 'fixme'::text AS "исправить",
    (a.tags ->> 'was:taxon'::text) IS NOT NULL AS "вырублен",
    a.tags ->> 'ref'::text AS ref_,
    a.tags - 'ref'::text - 'ref:start_date'::text - 'taxon'::text - 'taxon:ru'::text - 'genus'::text - 'genus:ru'::text - 'source:taxon'::text - 'natural'::text - 'leaf_cycle'::text - 'leaf_type'::text - 'start_date'::text - 'note'::text - 'description'::text - 'fixme'::text AS tags
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
     LEFT JOIN "Бирюлёвский дендропарк"."Участки" u ON st_intersects(u.geom, a.geom)
  WHERE (a.tags ->> 'ref'::text) IS NOT NULL AND ((a.tags ->> 'barrier'::text) IS NULL OR (a.tags ->> 'barrier'::text) <> 'gate'::text) AND (((a.tags ->> 'natural'::text) = ANY (ARRAY['wood'::text, 'scrub'::text, 'tree_row'::text, 'tree'::text])) OR (a.tags ->> 'barrier'::text) = 'hedge'::text)
  ORDER BY u."№", ((regexp_matches(a.tags ->> 'ref'::text, '\d+'::text))[1]::smallint);
*/

-- Сортировка по участкам и номеру маточной площадки
select *
from "Бирюлёвский дендропарк"."МП сверка Дмитрия" mp
order by split_part("Адрес", '×', 1)::int2 asc, replace(split_part("Адрес", '×', 2), '*', '');

-- Регулярный вид
with b as (
select "Адрес" ~ '\*' "OSM",
       "Адрес" !~ '\*' "План 1978",
       split_part("Адрес", '×', 1)::int2 "Уч.",
       replace(split_part("Адрес", '×', 2), '*', '') "№",
       split_part("Адрес", '×', 3) "№доп",
       "Флаг",
       unnest(regexp_split_to_array(mp."Растения", ';\s?')) "Вид или род"
from "Бирюлёвский дендропарк"."МП сверка Дмитрия" mp
)
select "OSM",
       "План 1978",
       "Уч.",
       "№",
       "№доп",
       "Флаг",
       regexp_replace("Вид или род", '\^|\*', '') "Вид или род",
       "Вид или род" ~ '\*' "Утрата",
       "Вид или род" ~ '\^' "После 2020"
from b
order by "Уч." asc, "№", "№доп";

