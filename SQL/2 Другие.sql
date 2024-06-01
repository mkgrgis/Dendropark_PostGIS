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
