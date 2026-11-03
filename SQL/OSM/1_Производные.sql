CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Видовые точки" as
with b as (
	select (tags ->> 'ref')::int2 "№",
		   (tags ->> 'name') "Название",
		   (tags ->> 'direction') α,
		   geom,
		   osm_type,
		   osm_id,
		   "OSM URL"
	  FROM "Бирюлёвский дендропарк: OSM"."∀" a
	 WHERE (tags ->> 'tourism') = 'viewpoint'
	 order by "№" nulls last
)
select geom,
	   "№",
	   "Название",
	   α,
	   case when α ~ '^\d+\-\d+$'
			then (regexp_substr(α, '^\d+')::int2 + regexp_substr(α, '\d+$')::int2) / 2.0
			when α ~ '^\d+$'
			then α::float
		 end ::float α₀,
	   osm_type,
	   osm_id,
       "OSM URL"
  from b;

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Флористические таблички" AS
select a.osm_id,
       a.osm_type,
       a.geom,
       u."№" "Уч.",
       a.tags ->> 'name' "название",
       a.tags ->> 'taxon' taxon,
       a.tags ->> 'taxon:ru' "вид",
       a.tags ->> 'genus' genus,
       a.tags ->> 'genus:ru' "род",
       a.tags ->> 'source:taxon' "подтв вида",
       a.tags ->> 'start_date' "создано",
       a.tags ->> 'note' "заметки",
       a.tags ->> 'description' "описание",
       a.tags ->> 'wikimedia_commons' "Файл ВикиСклада",
       a.tags - 'name' - 'tourism' - 'information' - 'board_type' - 'taxon' - 'taxon:ru' - 'genus' - 'genus:ru' - 'start_date' - 'note' - 'description' - 'wikimedia_commons' AS tags,
       a."OSM URL"
  from "Бирюлёвский дендропарк: OSM"."∀" a
  left join "Бирюлёвский дендропарк: OSM"."Участки" u
    on  st_intersects(u.geom, a.geom)
  where ((a.tags ->> 'tourism') = 'information' or (a.tags ->> 'was:tourism') = 'information')
    and ((a.tags ->> 'information') = 'board' or (a.tags ->> 'was:information') = 'board')
    and (a.tags ->> 'board_type') = 'plants'
  order by u."№";

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."ДТС 0"
AS SELECT st_union(geom) AS geom,
    tags ->> 'name'::text AS "Название"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (tags ->> 'highway'::text) IS NOT NULL
  GROUP BY (tags ->> 'name'::text);
COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."ДТС 0" IS 'Все элементы дорожно-тропиночной сети в зависимости от формы представления в OSM';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."ДТС"
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
   FROM "Бирюлёвский дендропарк: OSM"."ДТС 0" "д"
  ORDER BY "Название";
COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."ДТС" IS 'Сгруппированные по названию элементы дорожно-тропиночной сети';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Дороги"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'highway'::text AS highway,
    a.tags ->> 'surface'::text AS surface,
    a.tags ->> 'width'::text AS width,
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags,
    a."OSM URL"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL AND (a.tags ->> 'highway'::text) <> 'street_lamp'::text AND (a.tags ->> 'highway'::text) <> 'steps'::text;


CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Здания"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'building'::text AS building,
    a.tags ->> 'height'::text AS height,
    st_area(a.geom) AS "площадь",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'building'::text - 'name'::text - 'height'::text - 'note'::text - 'description'::text AS tags,
    a."OSM URL"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (a.tags ->> 'building'::text) IS NOT NULL;

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Лестницы"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    a.tags ->> 'name'::text AS name,
    a.tags ->> 'highway'::text AS highway,
    a.tags ->> 'surface'::text AS surface,
    a.tags ->> 'width'::text AS width,
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags,
    a."OSM URL"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (a.tags ->> 'highway'::text) IS NOT NULL AND (a.tags ->> 'highway'::text) = 'steps'::text;

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Мосты"
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
    a.tags ->> 'layer'::text AS l,
    a."OSM URL"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (a.tags ->> 'man_made'::text) = 'bridge'::text;

create or replace view "Бирюлёвский дендропарк: OSM"."ДТС Wikidata" as
select st_union(geom) geom,
       tags ->> 'name'::text AS "Название",
       tags ->> 'wikidata' "Q"
  from "Бирюлёвский дендропарк: OSM"."∀" a
 where (tags ->> 'highway'::text) is not null 
   and (tags ->> 'wikidata'::text) is not null
 group by (tags ->> 'name'::text), (tags ->> 'wikidata'::text);
comment on view "Бирюлёвский дендропарк: OSM"."ДТС Wikidata" is 'Дороги ДТС с указанием кода викиданных';

create or replace view "Бирюлёвский дендропарк: OSM"."Обсадки аллей Wikidata" as
select st_union(geom) geom,
       tags ->> 'wikidata' "Q"
  from "Бирюлёвский дендропарк: OSM"."∀" a
 where (tags ->> 'wikidata'::text) is not null
   and ((tags ->> 'natural'::text) = 'tree_row' 
    or (tags ->> 'barrier'::text) = 'hedge') 
 group by (tags ->> 'wikidata'::text);
comment on view "Бирюлёвский дендропарк: OSM"."Обсадки аллей Wikidata" is 'Обсадки и бордюры аллей с указанием кода викиданных';

-- конец