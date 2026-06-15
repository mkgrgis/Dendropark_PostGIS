-- Данные из экспликации Дмитрия: ДТС + дороги

drop view  "Бирюлёвский дендропарк: Дмитрий"."ДТС группы";
create view "Бирюлёвский дендропарк: Дмитрий"."ДТС группы" as
with b as (
select max("Время") over (partition by url) mt, "Время",
       atx,
       "№ строки"
  from "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки[]"
 where url = 'https://moscowparks.narod.ru/docs/explication.ods'
   and "№ листа" = 2
)
select "№ строки",
       coalesce(lead("№ строки") OVER (ORDER BY "№ строки"), 32768) AS "до",
       lower(atx[1]) "Группа",
       row_number() over () "№"
  from b
 where "Время" = mt -- По самому позднему из сохранённых файлов
   and "№ строки" > 1
   and atx[1] != ''
   and atx[1] = upper(atx[1])
 order by "№ строки";

-- drop materialized view "Бирюлёвский дендропарк: Дмитрий"."ДТС";
create materialized view "Бирюлёвский дендропарк: Дмитрий"."ДТС" as
with b as (
select max("Время") over (partition by url) mt, "Время",
       atx,
       "№ строки"
  from "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки[]"
 where url = 'https://moscowparks.narod.ru/docs/explication.ods'
   and "№ листа" = 2
)
select b."№ строки",
       g."Группа",
       atx[1] "Название по OSM",
       atx[2] "Название из пр. устр. 1964-1965 гг.",
       atx[3] "Длина аллеи, м., до 10м",
       atx[4] "Формирующий вид",
       atx[5] "Годы посадок",
       atx[6] "Количество по ведом. 1965 г.",
       atx[7] "Наличие комп. пос. 2018 г.",
       atx[8] "Кустарник-бордюр",
       atx[9] "Wikidata",
       regexp_replace(regexp_replace(atx[9], '^https?://', '', 'i'), '.*/', '') "Q",
       atx[10] "Примечание"       
  from b
inner join "Бирюлёвский дендропарк: Дмитрий"."ДТС группы" g
   on b."№ строки" > g."№ строки" and b."№ строки" < g.до 
 where "Время" = mt -- По самому позднему из сохранённых файлов
   and b."№ строки" > 2
   and atx[1] is not null
   and atx[1] != upper(atx[1])
 order by "№ строки";

refresh  materialized view "Бирюлёвский дендропарк: Дмитрий"."ДТС";

--drop  view "Бирюлёвский дендропарк: Дмитрий"."ДТС группы"


/*
create foreign table "Бирюлёвский дендропарк: Дмитрий"."Экспликация wget" (
    "Адрес" varchar null,
    "Сохранны" varchar null, -- Растительность по экспликациям 1978/2016 гг., подтверждённая,
    "Ведомость 1965 года" varchar null, -- Растительность по ведомости 1965 года,
    "Утрачено" varchar null, -- Растительность по экспликации 1978, исчезнувшая к 2016 г.,
    "Новая" varchar null, -- Растительность, высаженная в 2017-2019 гг., либо выявленная после 2005 г.,
    "Обсадка" varchar null
) server "Wiki дендропарк"
options ( program  'mkdir /tmp/exp;
cd /tmp/exp;
wget https://moscowparks.narod.ru/docs/explication.ods >/dev/null;
libreoffice --headless --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,false,true,false,false,false,-1 /tmp/exp/explication.ods > /dev/null;
cat explication-Лист1.csv;
', format 'csv', header 'true');
*/

-- Первичная форма экспликации до разбора пометок видов
-- drop view "Бирюлёвский дендропарк: Дмитрий"."Экспликация" cascade
create view "Бирюлёвский дендропарк: Дмитрий"."Экспликация" as
with b as (
select max("Время") over (partition by url) mt, "Время",
       atx, "№ строки"
  from "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки[]"
 where url = 'https://moscowparks.narod.ru/docs/explication.ods'
   and "№ листа" = 1
   and atx[1] != ''
)
select "№ строки",
       split_part(atx[1], '
', 1) "Адрес",
       split_part(atx[1], '
', 2) "Название",
       regexp_substr(atx[1], '^\d+')::int2 "Уч.",
       regexp_substr(atx[1], '(?<=×.?)\d+')::int2 "№сортировочный",
       regexp_substr(split_part(atx[1], '
', 1), '(?<=×).+') "№",
       atx[2] "Подтв. 1978/2016",
       atx[3] "Проект 1965",
       atx[4] "Исчез 1976-2016",
       atx[5] "По 1995",
       atx[6] "Новая",
       atx[7] "Обсадка или жив.изг."
  from b
 where "Время" = mt -- По самому позднему из сохранённых файлов
   and "№ строки" > 2
   and atx[1] is not null
   and regexp_substr(atx[1], '^\d+')::int2 is not null
 order by "№ строки";

comment on view "Бирюлёвский дендропарк: Дмитрий"."Экспликация" IS 'Наличие таблички у маточной площадки:
[+] — 2020 г., существует на начало ноября 2025, вид растительности указан корректно;
[•] — 2020 г., существует на начало ноября 2025, вид указан некорректно;
[×] — 2020 г., утрачена на начало ноября 2025, вид указан корректно;
[-] — 2020 г., утрачена на начало ноября 2025, вид был указан некорректно;
[S] — обр. 1960-х гг. (30×15 см), существует на начало ноября 2025;
[s] — обр. 1960-х, утрачена;
[b] — обр 2-й пол. 1980-х (примерно 80×50 см, все утрачены).'

comment on column "Бирюлёвский дендропарк: Дмитрий"."Экспликация"."Адрес" IS 'Участок × маточная площадка
*- новые м. пл.
или отд. раст.
б/№ - под вопр.
или отдельные растения';

-- Список номеров маточных площадок
refresh materialized view "Бирюлёвский дендропарк: Дмитрий"."№№ пл. по экспликациии";
create materialized view "Бирюлёвский дендропарк: Дмитрий"."№№ пл. по экспликациии" AS
select distinct "Уч.",
       "№сортировочный",
       "№",
       "Адрес"
 from "Бирюлёвский дендропарк: Дмитрий"."Экспликация"
where "Адрес" is not null
order by "Уч." asc, "№сортировочный" asc;