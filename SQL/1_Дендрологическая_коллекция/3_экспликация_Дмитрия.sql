create foreign table "Бирюлёвский дендропарк"."Экспликация от Дмитрия wget" (
    "Адрес" varchar null,
    "Табличка" varchar NULL,
    "Сохранны" varchar null, -- Растительность по экспликациям 1978/2016 гг., подтверждённая,
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

create materialized view "Бирюлёвский дендропарк"."Экспликация от Дмитрия" as
with b as (
select row_number() over ()::int2 "№ п/п",
       "Адрес",
       "Табличка",
       "Сохранны",
       "Утрачено",
       "Новая",
       "Обсадка"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия wget"
 where not ("Адрес" is null
            and "Табличка" is null
            and "Сохранны" is null
            and "Утрачено" is null
            and "Новая" is null
            and "Обсадка" is null
           )
)
select *
  from b;

COMMENT ON COLUMN "Бирюлёвский дендропарк"."Экспликация от Дмитрия"."№ п/п" IS 'Номер по порядку';
COMMENT ON COLUMN "Бирюлёвский дендропарк"."Экспликация от Дмитрия"."Адрес" IS 'Участок × маточная площадка
* - новые маточные площадки
или отдельные растения';
COMMENT ON COLUMN "Бирюлёвский дендропарк"."Экспликация от Дмитрия"."Табличка" IS 'Флаг и примечание таблички';
COMMENT ON COLUMN "Бирюлёвский дендропарк"."Экспликация от Дмитрия"."Сохранны" IS 'Растительность по экспликациям 1978/2016 гг., подтверждённая
(жирным выделены компенсационные посадки 2018-2019 гг.;
(жирным курсивом - компенсационные посадки с 2025 г.)';
COMMENT ON COLUMN "Бирюлёвский дендропарк"."Экспликация от Дмитрия"."Утрачено" IS 'Растительность по экспликации 1978, исчезнувшая к 2016 г.
(или см. год исчезновения в примечании)';
COMMENT ON COLUMN "Бирюлёвский дендропарк"."Экспликация от Дмитрия"."Новая" IS 'Растительность, высаженная в 2017-2019 гг., либо выявленная после
2005 г. (посадки 1978, 1986, 1998-1999, 2003, 2008, 2017-2020 гг.)';

refresh materialized view "Бирюлёвский дендропарк"."Экспликация от Дмитрия";

-- Список номеров маточных площадок
CREATE VIEW "Бирюлёвский дендропарк"."№№ пл. по экспликациии от Дмитрия" AS
select distinct regexp_substr("Адрес", '^\d+')::int2 "Уч.",
       regexp_substr("Адрес", '(?<=×.?)\d+')::int2 "№_",
       regexp_substr("Адрес", '(?<=×).+') "№",
       split_part("Адрес", '
', 1) "Адрес"
 from "Бирюлёвский дендропарк"."Экспликация от Дмитрия"
where "Адрес" is not null
  and regexp_substr("Адрес", '^\d+') is not null 
order by "Уч." asc, "№_" asc;

,  unnest(string_to_array("Утрачено", '
')) "Утрата", "Новая",
, "Обсадка"

with d as (
select split_part("Адрес"::text, '
'::text, 1) AS "Адрес эксп",
       regexp_substr("Адрес"::text, '^\d+'::text)::smallint AS "Уч.",
       regexp_substr("Адрес"::text, '(?<=×.?)\d+'::text)::smallint AS "№",
       regexp_substr("Адрес"::text, '(?<=×).+'::text) AS "№_",
       "Табличка", unnest(string_to_array("Сохранны", '
')) "Род или вид",
true "Экспликация"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия"
),
p as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    "Адрес" "Адрес пасп",
    "Род или вид",
    true "Паспорт"
   FROM "Бирюлёвский дендропарк".wiki_kod
)
select *
from d
full outer join p
using ("Уч.", "№", "Род или вид")
order by "Уч." asc, "№" asc

with d as (
select split_part("Адрес"::text, '
'::text, 1) AS "Адрес эксп",
       regexp_substr("Адрес"::text, '^\d+'::text)::smallint AS "Уч.",
       regexp_substr("Адрес"::text, '(?<=×.?)\d+'::text)::smallint AS "№",
       regexp_substr("Адрес"::text, '(?<=×).+'::text) AS "№_",
       "Табличка", unnest(string_to_array("Утрачено", '
')) "Род или вид",
true "Экспликация"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия"
),
p as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    "Адрес" "Адрес пасп",
    "Род или вид",
    true "Паспорт"
   FROM "Бирюлёвский дендропарк".wiki_kod
)
select *
from d
full outer join p
using ("Уч.", "№", "Род или вид")
order by "Уч." asc, "№" asc

