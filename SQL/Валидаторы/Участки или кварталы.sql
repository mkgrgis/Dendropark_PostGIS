-- Перечни участков или кварталов дендропарка
-- drop view "Бирюлёвский дендропарк"."Участки сводка №№";
create or replace view "Бирюлёвский дендропарк"."Участки сводка №№" as
with w as (
select distinct 
       true wiki,
       "Уч."
  from "Бирюлёвский дендропарк: Википедия"."№№ пл. по Википедии"
),
p as (
select distinct
       true "ОКН",
       "Уч."
  from "Бирюлёвский дендропарк: ОКН"."№№ пл. по паспорту ОКН"
),
o as (
select u."№" "Уч.",       
       "Описание",
       --ST_AsGeoJSON(geom) "GeoJSON",
       geom "Контур границ",
       "OSM URL",
       "Старые номера",
       true "ОСМ"
  from "Бирюлёвский дендропарк: OSM"."Участки" u
),
d as (
select distinct
       true "каталог Дмитрия",
       "Уч."
  from "Бирюлёвский дендропарк: Дмитрий"."Экспликация"
),
p1965 as (
select distinct
       true "проект 1965",
       "Уч."
  from "Бирюлёвский дендропарк: проект 1965"."№№ пл. в 1965 г."
),
p1997p1 as (
select distinct
       true "проект 1996 П1",
       "НомерКв" "Уч."       
  from "Бирюлёвский дендропарк: проект 1997"."Приложение №1" п
),
p1997p2 as (
select distinct
       true "проект 1996 П2",
       "НомерКв" "Уч."
  from "Бирюлёвский дендропарк: проект 1997"."Приложение №2" п
)/* ,
p1997p3 as (
select distinct
       true "проект 1996 П3",
       "НомерКв" "Уч."
  from "Бирюлёвский дендропарк: проект 1997"."Приложение №3" п
) */,
fto as (
select distinct
       true "таблички ОСМ",
       "Уч."
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички"
),
ftw as (
select distinct
       true "таблички Википедия",
       "Уч."
  from "Бирюлёвский дендропарк: Википедия"."Флористические таблички"
)
select *      
  from o
  full outer join p
 using ("Уч.")
  full outer join d
 using ("Уч.")
  full outer join w
 using ("Уч.")
  full outer join p1965
 using ("Уч.")
  full outer join p1997p1
 using ("Уч.")
  full outer join p1997p2
 using ("Уч.")
/*  full outer join p1997p3
 using ("Уч.") */
  full outer join fto
 using ("Уч.")
  full outer join ftw
 using ("Уч.")
 order by "Уч.";