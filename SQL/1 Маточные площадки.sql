-- "Бирюлёвский дендропарк"."Маточные площадки" исходный текст

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
  
-- "Бирюлёвский дендропарк"."Таблички маточных площадок" исходный текст

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Таблички маточных площадок"
AS SELECT a.osm_id,
    a.osm_type,
    a.geom,
    u."№" AS "Уч.",
    a.tags ->> 'name'::text AS "название",
    a.tags ->> 'taxon'::text AS taxon,
    a.tags ->> 'taxon:ru'::text AS "вид",
    a.tags ->> 'genus'::text AS genus,
    a.tags ->> 'genus:ru'::text AS "род",
    a.tags ->> 'source:taxon'::text AS "подтв вида",
    a.tags ->> 'start_date'::text AS "создано",
    a.tags ->> 'note'::text AS "заметки",
    a.tags ->> 'description'::text AS "описание",
    a.tags - 'name'::text - 'tourism'::text - 'information'::text - 'board_type'::text - 'taxon'::text - 'taxon:ru'::text - 'genus'::text - 'genus:ru'::text - 'start_date'::text - 'note'::text AS tags
   FROM "Бирюлёвский дендропарк"."OSM ∀" a
     LEFT JOIN "Бирюлёвский дендропарк"."Участки" u ON st_intersects(u.geom, a.geom)
  WHERE (a.tags ->> 'tourism'::text) = 'information'::text AND (a.tags ->> 'information'::text) = 'board'::text AND (a.tags ->> 'board_type'::text) = 'plants'::text
  ORDER BY u."№";  
  

-- "Бирюлёвский дендропарк"."Фото табличек маточных площадок" исходный текст

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Фото табличек маточных площадок"
AS SELECT "WikiMap ∀".pageid,
    "WikiMap ∀".title,
    "WikiMap ∀"."φλ₀",
    "WikiMap ∀"."α₀",
    "WikiMap ∀"."f₀",
    "WikiMap ∀".c,
    "WikiMap ∀"."φλ₁",
    "WikiMap ∀"."α₁",
    "WikiMap ∀"."f₁",
    "WikiMap ∀".tag,
    "WikiMap ∀".ns,
    "WikiMap ∀".u,
    "WikiMap ∀".img,
    "WikiMap ∀"."URL",
    "WikiMap ∀"."Vue",
    (regexp_match("WikiMap ∀".title, '(?<=^File\:Табличка «).+?(?=»)'::text))[1] AS "Название",
    (regexp_match("WikiMap ∀".title, '(?<=на участке )\d+(?=[ \.])'::text))[1]::smallint AS "Уч. назв",
    u₀."№" AS "Уч.φλ₀",
    u₁."№" AS "Уч.φλ₁",
    COALESCE("WikiMap ∀"."φλ₁", "WikiMap ∀"."φλ₀") AS "φλ"
   FROM "Бирюлёвский дендропарк"."WikiMap ∀"
     LEFT JOIN "Бирюлёвский дендропарк"."Участки" u₀ ON st_intersects(u₀.geom, "WikiMap ∀"."φλ₀")
     LEFT JOIN "Бирюлёвский дендропарк"."Участки" u₁ ON st_intersects(u₁.geom, "WikiMap ∀"."φλ₁")     
  WHERE "WikiMap ∀".title ~ '^File\:Табличка'::text;
