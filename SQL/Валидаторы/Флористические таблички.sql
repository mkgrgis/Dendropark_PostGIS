refresh materialized view "Бирюлёвский дендропарк: Википедия"."Флористические таблички";

-- Числа табличек по разным источникам
select count (*) число, 'OSM' тип
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички" o
 union all
select count (*) число, 'ВикиСклад' тип
  from "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички"
union all
select count (*) число, 'Википедия' тип
  from "Бирюлёвский дендропарк: Википедия"."Флористические таблички";

-- Полностью комплектные случаи, таблички представлены везде
-- 149 табличек представляют флору площадок и аллей 
create or replace view "Бирюлёвский дендропарк"."Полные флористические таблички" as
select o.osm_id is not null "OSM",
       wc.pageid is not null "Викисклад",
       (wp."Адрес" is not null or wp."Указание на аллею" is not null) "Википедия",
       wp."Адрес" is not null "флора площадки", -- опущенный флаг указывает на флору аллеи
       wp."OSM URL" = o."OSM URL" "OSM URL eq",
       wp."Название" = o.название "Название eq",
       lower(wp."Название") ~ lower(coalesce(o.род, ((regexp_match(o.вид, '(?<=(^|\n)\s*?)\S+'))[1]))) is true "род eq",
       coalesce(o.род, ((regexp_match(o.вид, '(?<=(^|\n)\s*?)\S+'))[1]))
        систематика,
       wp."Название" "wp назв",
       o.название "OSM назв",
       o.tags ->> 'was:tourism'::text = 'information' "Демонтирована",       
       round(ST_Distance(wc.φλ₁::geography, o.geom::geography)::numeric, 1) "От фото до ОСМ точки",
       round(ST_Distance(wc.φλ₀::geography, o.geom::geography)::numeric, 1) "От фотографа до ОСМ точки",
       o."OSM URL",
       wc."URL" "ВикиСклад URL",
       wp."Адрес",
       wc."Уч.",
       o.geom "φλ OSM",
       wc.φλ₁,
       wc.φλ₀
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички" o
  full outer join "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички" wc
    on wc.title = o."Файл ВикиСклада"
  full outer join "Бирюлёвский дендропарк: Википедия"."Флористические таблички" wp
    on wp."Файл" = o."Файл ВикиСклада" 
 where o.osm_id is not null -- Представлено везде
   and wc.pageid is not null
   and (wp."Адрес" is not null or wp."Указание на аллею" is not null)
   and wp."OSM URL" = o."OSM URL" -- Правильно указывается
   and wp."Название" = o.название
 order by wc."Уч." asc, "Адрес"
;

-- Некомплектные случаи: 1 дубль фото на Викискладе + 1 табличка образца 1962 года + OSM плакаты о растениях
select o.osm_id is not null "OSM",
       wc.pageid is not null "Викисклад",
       wp."Адрес" is not null "Википедия",
       wp."Название" "wp назв",
       o.название "OSM назв",
       wc.title,
       wp."Файл",
       o.tags ->> 'wikimedia_commons' "OSM файл",
       wp."Указание на аллею",
       o.tags ->> 'was:tourism'::text = 'information' "Демонтирована",       
       round(ST_Distance(wc.φλ₁::geography, o.geom::geography)::numeric, 1) "От фото до ОСМ точки",
       round(ST_Distance(wc.φλ₀::geography, o.geom::geography)::numeric, 1) "От фотографа до ОСМ точки",
       'https://openstreetmap.org/'|| osm_type || '/' || osm_id "OSM URL",
       wc."URL" "ВикиСклад URL",
       wp."Адрес",
       o.geom "φλ OSM",
       wc.φλ₁,
       wc.φλ₀
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички" o
  full outer join "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички" wc
    on wc.title = o."Файл ВикиСклада"
  full outer join "Бирюлёвский дендропарк: Википедия"."Флористические таблички" wp
    on wp."Файл" = o."Файл ВикиСклада"
 where not (o.osm_id is not null
       and wc.pageid is not null
       and (wp."Адрес" is not null or wp."Указание на аллею" is not null)
       and wp."OSM URL" = o."OSM URL" and  wp."Название" = o.название
       );

with b as (
select "Адрес",
       unnest(string_to_array(e."Подтв. 1978/2016", E'\n')) t
  from "Бирюлёвский дендропарк: Дмитрий"."Экспликация" e
union all
select "Адрес",
       unnest(string_to_array(e."Исчез 1976-2016", E'\n')) t
  from "Бирюлёвский дендропарк: Дмитрий"."Экспликация" e
union all
select "Адрес",
       unnest(string_to_array(e."По 1995"  , E'\n')) t
  from "Бирюлёвский дендропарк: Дмитрий"."Экспликация" e  
union all
select "Адрес",
       unnest(string_to_array(e."Новая"  , E'\n')) t
  from "Бирюлёвский дендропарк: Дмитрий"."Экспликация" e
),
fl as (
select "Адрес",
       regexp_replace(t, '^.*?(\[|$)', '') fl,
       t
  from b
),
fl1 as (
select "Адрес",
       regexp_replace(fl, '\].*?$', '') флаг,
       regexp_replace(fl, '\].*?$', '') IN ('+', '•', '×', '-') "2020",
       t "У Дмитрия"
  from fl
 where fl != ''
 )
 select "Адрес",
        флаг,
        "2020",
        k."OSM назв",
        "У Дмитрия"
   from fl1
   full join "Бирюлёвский дендропарк"."Полные флористические таблички" k
  using ("Адрес")  
  order by "У Дмитрия" is not null desc,
           "2020" is true desc,
           fl1."Адрес"

-- конец