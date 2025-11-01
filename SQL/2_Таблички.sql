CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Таблички маточных площадок OSM" AS
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
  
CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Таблички маточных площадок Wiki" as
select w.pageid,
       w.title,
       w."φλ₀",
       w."α₀",
       w."f₀",
       w.c,
       w."φλ₁",
       w."α₁",
       w."f₁",
       w.tag,
       w.ns,
       w.u,
       w.img,
       w."URL",
       w."Vue",
       (regexp_match(w.title, '(?<=^File\:Табличка «).+?(?=»)'))[1] AS "Название",
       (regexp_match(w.title, '(?<=на участке )\d+(?=[ \.])'))[1]::smallint AS "Уч. назв",
       coalesce(u₁."№", u₀."№") "Уч.",
       (regexp_match(w.title, '(?<=на участке )\d+(?=[ \.])'))[1]::smallint = coalesce(u₁."№", u₀."№") "ДА", 
       u₀."№" AS "Уч.φλ₀",
       u₁."№" AS "Уч.φλ₁",
       coalesce(w."φλ₁", w."φλ₀") AS "φλ"
  from "Бирюлёвский дендропарк"."Wikimap curl" w
  left join "Бирюлёвский дендропарк"."Участки" u₀
    on st_intersects(u₀.geom, w."φλ₀")
  left join "Бирюлёвский дендропарк"."Участки" u₁
    on st_intersects(u₁.geom, w."φλ₁")
  where w.title ~ '^File\:Табличка'
  order by coalesce(u₁."№", u₀."№");

SET http.curlopt_timeout_msec = 200000;
-- Получение данных без промежуточных утилит
refresh materialized view "Бирюлёвский дендропарк"."Wikimap curl";

select * from "Бирюлёвский дендропарк".wiki_таблички;

-- 140
select round(ST_Distance(w.φλ::geography, o.geom::geography)::numeric, 1) d,
       lower(w."Название") ~ lower(o.род) n,
       *  
  from "Бирюлёвский дендропарк"."Таблички маточных площадок OSM" o
  -- full outer 
 join "Бирюлёвский дендропарк"."Таблички маточных площадок Wiki" w
    on w.title = o.tags ->> 'wikimedia_commons' 
   
       
-- 3 мусорных объекта     
select 'https://openstreetmap.org/'|| osm_type || '/' || osm_id "URL",
       o."Уч.", название, o.taxon   
  from "Бирюлёвский дендропарк"."Таблички маточных площадок OSM" o
  full outer 
 join "Бирюлёвский дендропарк"."Таблички маточных площадок Wiki" w
    on w.title = o.tags ->> 'wikimedia_commons'
where w."Название" is null

-- 1, дубликат
select pageid, "URL", title "Название"  
  from "Бирюлёвский дендропарк"."Таблички маточных площадок OSM" o
  full outer 
 join "Бирюлёвский дендропарк"."Таблички маточных площадок Wiki" w
    on w.title = o.tags ->> 'wikimedia_commons'
where o.osm_id is null;

-- Все OSM объекты табличек 2020 года имеют привязку фотографии с ВикиСклада.

