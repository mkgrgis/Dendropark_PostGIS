CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Ценные видовые раскрытия" as
with b as (
	select (tags ->> 'ref')::int2 "№",
		   (tags ->> 'name') "Название",
		   (tags ->> 'direction') α,
		   geom,
		   osm_type,
		   osm_id
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
	   osm_id
  from b;

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Таблички маточных площадок" AS
select a.osm_id,
       a.osm_type,
       a.geom,
       u."№" AS "Уч.",
       a.tags ->> 'name' AS "название",
       a.tags ->> 'taxon' AS taxon,
       a.tags ->> 'taxon:ru' AS "вид",
       a.tags ->> 'genus' AS genus,
       a.tags ->> 'genus:ru' AS "род",
       a.tags ->> 'source:taxon' AS "подтв вида",
       a.tags ->> 'start_date' AS "создано",
       a.tags ->> 'note' AS "заметки",
       a.tags ->> 'description' AS "описание",
       a.tags - 'name' - 'tourism' - 'information' - 'board_type' - 'taxon' - 'taxon:ru' - 'genus' - 'genus:ru' - 'start_date' - 'note' AS tags
  from "Бирюлёвский дендропарк"."OSM ∀" a
  left join "Бирюлёвский дендропарк"."Участки" u
    on  st_intersects(u.geom, a.geom)
  where ((a.tags ->> 'tourism') = 'information' or (a.tags ->> 'was:tourism') = 'information')
    and ((a.tags ->> 'information') = 'board' or (a.tags ->> 'was:information') = 'board')
    and (a.tags ->> 'board_type') = 'plants'
  order by u."№";
  
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


CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."ДТС 0"
AS SELECT st_union(geom) AS geom,
    tags ->> 'name'::text AS "Название"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (tags ->> 'highway'::text) IS NOT NULL
  GROUP BY (tags ->> 'name'::text);

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
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags
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
    a.tags - 'building'::text - 'name'::text - 'height'::text - 'note'::text - 'description'::text AS tags
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
    a.tags - 'highway'::text - 'surface'::text - 'width'::text - 'note'::text - 'description'::text AS tags
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
    a.tags ->> 'layer'::text AS l
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (a.tags ->> 'man_made'::text) = 'bridge'::text;

