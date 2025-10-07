-- Перечни номеров маточных площадок
create or replace view "Бирюлёвский дендропарк"."№№ пл. сводка №№" as
with w as (
select true wiki,
       "Уч.",
       "№"::text "№"
  from "Бирюлёвский дендропарк"."№№ пл. по Википедии" 
),
p as (
select true "ОКН",
       "Уч.",
       "№"::text "№"
  from "Бирюлёвский дендропарк"."№№ пл. по паспорту ОКН" 
),
o as (
select distinct true "ОСМ",       
       "Уч.",
       "№" "ref OSM",
       "ref" "№",
       "из ОКН",
       "объектов OSM",
       case when "объектов OSM" =1 then "URL" else null end "URL"
  from "Бирюлёвский дендропарк"."№№ пл. по ОСМ" s
-- where s."из ОКН" 
),
d as (
select true "каталог Дмитрия",
       "Уч.", "№_" "№ Дм", "№", "Адрес" "Адрес Дм"
  from "Бирюлёвский дендропарк"."№№ пл. по экспликациии от Дмитрия"    
)
select *
  from w
  full outer join p
 using ("Уч.", "№")
  full outer join o
 using ("Уч.", "№")
  full outer join d
 using ("Уч.", "№")
 order by "Уч.", "№";

select *
  from "Бирюлёвский дендропарк"."№№ пл. сводка №№" s
 where (s.wiki is null
        or "ОКН" is null
        or "ОСМ" is null
        or "каталог Дмитрия" is null
       )
   and not -- согласовано между OSM и экспликацией Дмитрия и нет в паспорте ОКН и на Википедии
       (s.wiki is null
        and "ОКН" is null
        and "ОСМ"
        and "каталог Дмитрия"
        --and "№" ~ '^Р' -- экспозиция редких
       )
;

create or replace view "Бирюлёвский дендропарк"."№№ пл. сводка адресов" as
with w as (
select true wiki,
       "Уч." "Уч. w",
       "№"::text "№ w",
       "Адрес"
  from "Бирюлёвский дендропарк"."№№ пл. по Википедии" 
),
p as (
select true "ОКН",
       "Уч." "Уч. ОКН",
       "№"::text "№ ОКН",
       "Адрес"
  from "Бирюлёвский дендропарк"."№№ пл. по паспорту ОКН" 
),
o as (
select distinct true "ОСМ",       
       "Уч." "Уч. ОСМ",
       "№" "ref OSM",
       "ref" "№ ОСМ",
       "из ОКН",
       "объектов OSM",
       "Уч." || '×' || "ref" "Адрес",
       case when "объектов OSM" = 1 then "URL" else null end "URL"
  from "Бирюлёвский дендропарк"."№№ пл. по ОСМ" s
-- where s."из ОКН" 
),
d as (
select true "каталог Дмитрия",
       "Уч." "Уч. Дм", "№_" "№ Дм", "№" "№_ Дм", trim("Адрес") "Адрес"
  from "Бирюлёвский дендропарк"."№№ пл. по экспликациии от Дмитрия"    
)
select *
  from w
  full outer join p
 using ("Адрес")
  full outer join o
 using ("Адрес")
  full outer join d
 using ("Адрес")
 order by "Адрес";

-- Всего 768
-- Всего 744
 select count(*) n
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов";
  
-- Полностью совпадают 481 из 768
-- Полностью совпадают 489 из 744
 select count(*) n
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
 where wiki is not null and "ОКН" is not null and "ОСМ" is not null and "каталог Дмитрия" is not null
 
-- Где-то чего-то нет 287 из 768
-- Где-то чего-то нет 255 из 744
 select count(*) n
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
 where not(wiki is not null and "ОКН"  is not null and "ОСМ" is not null and "каталог Дмитрия" is not null)
 
-- согласовано между OSM и экспликацией Дмитрия и нет в паспорте ОКН и на Википедии 137 из 287
-- согласовано между OSM и экспликацией Дмитрия и нет в паспорте ОКН и на Википедии 153 из 255
 select count(*) n
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
 where not (wiki is not null and "ОКН"  is not null and "ОСМ"  is not null and "каталог Дмитрия" is not null)
       and (wiki is null and "ОКН" is null and "ОСМ" is not null and "каталог Дмитрия" is not null) 
 
-- на рассмотрение 150
-- на рассмотрение 102
 select count(*) n
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
 where not (wiki is not null and "ОКН"  is not null and "ОСМ"  is not null and "каталог Дмитрия" is not null)
       and not (wiki is null and "ОКН" is null and "ОСМ" is not null and "каталог Дмитрия" is not null)
       
 
 select *
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
 where not (wiki is not null and "ОКН"  is not null and "ОСМ"  is not null and "каталог Дмитрия" is not null)
       and not (wiki is null and "ОКН" is null and "ОСМ" is not null and "каталог Дмитрия" is not null)
       
-- Ошибки пробела
select "Адрес" ~ ' $' "Ошибка пробела",
        "Адрес", "№_ Дм"
  from "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
 where not (wiki is not null and "ОКН"  is not null and "ОСМ"  is not null and "каталог Дмитрия" is not null)
       and not (wiki is null and "ОКН" is null and "ОСМ" is not null and "каталог Дмитрия" is not null)
       and "Адрес" ~ ' $'

       
       CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."№№ пл. сводка адресов"
AS WITH w AS (
         SELECT true AS wiki,
            "№№ пл. по Википедии"."Уч." AS "Уч. w",
            "№№ пл. по Википедии"."№"::text AS "№ w",
            "№№ пл. по Википедии"."Адрес"
           FROM "Бирюлёвский дендропарк"."№№ пл. по Википедии"
        ), p AS (
         SELECT true AS "ОКН",
            "№№ пл. по паспорту ОКН"."Уч." AS "Уч. ОКН",
            "№№ пл. по паспорту ОКН"."№"::text AS "№ ОКН",
            "№№ пл. по паспорту ОКН"."Адрес"
           FROM "Бирюлёвский дендропарк"."№№ пл. по паспорту ОКН"
        ), o AS (
         SELECT DISTINCT true AS "ОСМ",
            s."Уч." AS "Уч. ОСМ",
            s."№" AS "ref OSM",
            s.ref AS "№ ОСМ",
            s."из ОКН",
            s."объектов OSM",
                CASE
                    WHEN s."объектов OSM" = 1 THEN s."URL"
                    ELSE NULL::text
                END AS "URL",
            (s."Уч." || '×'::text) || s.ref AS "Адрес"
           FROM "Бирюлёвский дендропарк"."№№ пл. по ОСМ" s
        ), d AS (
         SELECT true AS "каталог Дмитрия",
            "№№ пл. по экспликациии от Дмитрия"."Уч." AS "Уч. Дм",
            "№№ пл. по экспликациии от Дмитрия"."№_" AS "№ Дм",
            "№№ пл. по экспликациии от Дмитрия"."№",
            "№№ пл. по экспликациии от Дмитрия"."Адрес"
           FROM "Бирюлёвский дендропарк"."№№ пл. по экспликациии от Дмитрия"
        )
 SELECT "Адрес",
    w.wiki,
    w."Уч. w",
    w."№ w",
    p."ОКН",
    p."Уч. ОКН",
    p."№ ОКН",
    o."ОСМ",
    o."Уч. ОСМ",
    o."ref OSM",
    o."№ ОСМ",
    o."из ОКН",
    o."объектов OSM",
    o."URL",
    d."каталог Дмитрия",
    d."Уч. Дм",
    d."№ Дм",
    d."№"
   FROM w
     FULL JOIN p USING ("Адрес")
     FULL JOIN o USING ("Адрес")
     FULL JOIN d USING ("Адрес");
*/