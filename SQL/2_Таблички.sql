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

create or replace view "Бирюлёвский дендропарк"."Экспликация от Дмитрия доп" as
select coalesce(s."Адрес", split_part(e."Адрес", '
', 1)) "Адрес", e."Сохранны", e."Утрачено", e."Обсадка"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия" e
  left join ( -- Доопределение старых обозначений маточных площадок, Дмитрий таких сведений не публикует
    select "Адрес",
           split_part("Адрес", '(', 1) "Сокр"
      from "Бирюлёвский дендропарк"."№№ пл. по паспорту ОКН" o
     where o."Адрес" ~'\('
            ) s
     on s."Сокр" = e."Адрес";

-- Сводка из экспликации Дмитрия с участием флага таблички рядом с видом
select "Адрес", "Изображение", "Род или вид wiki",
       с."Табличка" "сТабличка", с."Вид или род" "сВид или род", с."Примечание" "сПримечание",
       у."Табличка" "уТабличка", у."Вид или род" "уВид или род", у."Примечание" "уПримечание",
       н."Табличка" "нТабличка", н."Вид или род" "нВид или род", н."Примечание" "нПримечание"
 from "Бирюлёвский дендропарк".wiki_таблички w
full join (select * from "Бирюлёвский дендропарк"."Экспликация от Дмитрия сохр" с where "Табличка" is not null) с
using("Адрес")
full join (select * from "Бирюлёвский дендропарк"."Экспликация от Дмитрия утр" у where "Табличка" is not null) у
using("Адрес")
full join (select * from "Бирюлёвский дендропарк"."Экспликация от Дмитрия нов" н where "Табличка" is not null) н
using("Адрес")
order by regexp_substr("Адрес"::text, '^\d+'::text)::smallint asc,
       regexp_substr("Адрес"::text, '(?<=×.?)\d+'::text)::smallint asc;

select "Адрес", "Изображение", "Род или вид wiki", "Табличка", "Вид или род", "Примечание" from "Бирюлёвский дендропарк".wiki_таблички w
full join (select * from "Бирюлёвский дендропарк"."Экспликация от Дмитрия утр" where "Табличка" is not null) с
using("Адрес")
order by regexp_substr("Адрес"::text, '^\d+'::text)::smallint asc,
       regexp_substr("Адрес"::text, '(?<=×.?)\d+'::text)::smallint asc;

     
     
     ) e
using("Адрес")
where "Адрес" is not null and (e."Табличка" is not null or w."Изображение" is not null)
order by regexp_substr("Адрес"::text, '^\d+'::text)::smallint asc,
       regexp_substr("Адрес"::text, '(?<=×.?)\d+'::text)::smallint asc;

-- Подозрение на нехватку фото
select "Адрес", "Табличка", "Сохранны", "Утрачено"
from "Бирюлёвский дендропарк"."Таблички Дм" where "Изображение" is null;

-- Существующее фото не отмечено
select "Адрес", "Изображение", "ОКН", "OSM URL"
from "Бирюлёвский дендропарк"."Таблички Дм" where "Табличка" is null;

select e.* from "Бирюлёвский дендропарк"."Экспликация от Дмитрия" e
left join "Бирюлёвский дендропарк".wiki_таблички w
using("Адрес")
where w."Изображение" is null and e."Табличка" != ''

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

