-- Сверка видового состава
refresh materialized view "Бирюлёвский дендропарк"."Экспликация от Дмитрия";
refresh materialized view "Бирюлёвский дендропарк".wiki_таблички;
refresh materialized view "Бирюлёвский дендропарк".wiki_флора;


create or replace view "Бирюлёвский дендропарк"."Виды Дм + ОКН" as
-- Совпадение сохранных видов и родов на маточных площадках
with ds as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    s."Адрес" "Адрес с",
    s."Табличка" "Таб с",
    s."Примечание" "Прим с",
    s."Вид или род",
    true "Экспликация с"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия сохр" s
),
du as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    u."Адрес" "Адрес у",
    u."Табличка" "Таб у",
    u."Примечание" "Прим у",
    u."Вид или род",
    true "Экспликация у"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия утр" u
),
dn as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    u."Адрес" "Адрес н",
    u."Табличка" "Таб н",
    u."Примечание" "Прим н",
    u."Вид или род",
    true "Экспликация н"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия нов" u
),
p as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    "Адрес" "Адрес пасп",
    "Вид или род",
    true "Паспорт"
   FROM "Бирюлёвский дендропарк".wiki_флора wф 
)
select "Уч.", "№", "Вид или род",
       "Паспорт" is not null "Паспорт",
       "Экспликация с" is not null "Экспликация с",
       "Экспликация у" is not null "Экспликация у",
       "Экспликация н" is not null "Экспликация н",
       coalesce ("Адрес с", "Адрес у", "Адрес н") "Адрес Дм",
       coalesce ("Таб с", "Таб у", "Таб н") "Таб Дм",
       coalesce ("Прим с", "Прим у", "Прим н") "Прим Дм"
from ds
full outer join du
using ("Уч.", "№", "Вид или род")
full outer join dn
using ("Уч.", "№", "Вид или род")
full outer join p
using ("Уч.", "№", "Вид или род")
order by "Уч." asc, "№" asc;

-- 788
-- 1089 разных данных всего (с новыми насаждениями)
-- 1081
select count (*) n from "Бирюлёвский дендропарк"."Виды Дм + ОКН";
select *   
 from "Бирюлёвский дендропарк"."Виды Дм + ОКН";

-- 453 совпали сразу
-- 475
select count (*) n from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where "Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н");
select * from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where "Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н");

-- 636 не совпали
-- 606
select count (*) n from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where not ("Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н"));
select * from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where not ("Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н"));

-- Не сопоставляемые, мимо паспорта
-- 216
-- 221
select count (*) n from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where not ("Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н"))
      and regexp_like("Адрес Дм", '\*');
select * from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where not ("Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н"))
      and regexp_like("Адрес Дм", '\*');

-- Не сопоставляемые
-- 420
-- 385
select count (*) n from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where not ("Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н"))
      and (not regexp_like("Адрес Дм", '\*') or "Адрес Дм" is null);
select * from "Бирюлёвский дендропарк"."Виды Дм + ОКН"
where not ("Паспорт" and ("Экспликация с" or "Экспликация у" or "Экспликация н"))
      and (not regexp_like("Адрес Дм", '\*') or "Адрес Дм" is null);

with d as (
select split_part("Адрес"::text, '
'::text, 1) AS "Адрес эксп",
       regexp_substr("Адрес"::text, '^\d+'::text)::smallint AS "Уч.",
       regexp_substr("Адрес"::text, '(?<=×.?)\d+'::text)::smallint AS "№",
       regexp_substr("Адрес"::text, '(?<=×).+'::text) AS "№_",
       unnest(string_to_array("Утрачено", '
')) "Вид или род",
true "Экспликация"
  from "Бирюлёвский дендропарк"."Экспликация от Дмитрия"
),
p as (
select regexp_substr("Адрес", '^\d+'::text)::smallint AS "Уч.",
    regexp_substr("Адрес", '(?<=×)\d+'::text)::smallint AS "№",
    "Адрес" "Адрес пасп",
    "Вид или род",
    true "Паспорт"
   FROM "Бирюлёвский дендропарк".wiki_флора 
)
select *
from d
full outer join p
using ("Уч.", "№", "Вид или род")
order by "Уч." asc, "№" asc;


-- Сводка по совпадению рода
select s."Уч.", s."№", o.*, d.*, p.*
from "Бирюлёвский дендропарк"."№ площадок сводка" s
left join "Бирюлёвский дендропарк"."Виды по OSM" o
  on s."Уч." = o."Уч." and s."№" = o."№"
left join "Бирюлёвский дендропарк"."Виды по сверке Дмитрия" d
  on s."Уч." = d."Уч." and s."№" = d."№" and not d."Утрата" and o.род = regexp_substr(d."Вид или род", '^\S+')
left join "Бирюлёвский дендропарк"."Виды по паспорту ОКН" p
  on s."Уч." = p."Уч." and s."№" = p."№" and not p."Утрата" and o.род = regexp_substr(p."Вид или род", '^\S+')
order by s."Уч." asc, s."№", "Код";


-- Данные OSM с массивами
create view "Бирюлёвский дендропарк"."OSM посадки растений" as

select  distinct 
	m.*,
    (string_to_array(a.tags ->> 'taxon'::text, ';'::text)) AS taxon,
    (string_to_array(a.tags ->> 'taxon:ru'::text, ';'::text)) AS "вид",
    (string_to_array(a.tags ->> 'genus'::text, ';'::text)) AS genus,
    (string_to_array(a.tags ->> 'genus:ru'::text, ';'::text)) AS "род",
    a.tags ->> 'source:taxon'::text AS "Подтверждение",
    a.tags ->> 'natural'::text AS "Тип посадки",
    a.tags ->> 'leaf_cycle'::text AS "Листопадность",
    a.tags ->> 'leaf_type'::text AS "Листва",
    a.tags ->> 'start_date'::text AS "Создано",
    a.tags ->> 'note'::text AS "Заметки",
    a.tags ->> 'description'::text AS "Описание",
    a.tags ->> 'fixme'::text AS "Исправить",
    (a.tags ->> 'was:taxon'::text) IS NOT NULL AS "Вырублен"  
   from "Бирюлёвский дендропарк"."OSM ∀" a 
   left join "Бирюлёвский дендропарк"."Участки" u ON st_within(a.geom, u.geom)
   left join "Бирюлёвский дендропарк"."№№ пл. по ОСМ" m
     on m."Уч." =  u."№"
    and m."№"::text  = a.tags ->> 'ref'
   where (a.tags ->> 'ref'::text) is not null
     and ((a.tags ->> 'barrier') is null or (a.tags ->> 'barrier'::text) <> 'gate'::text)
     and (((a.tags ->> 'natural'::text) = any (array['wood'::text, 'scrub'::text, 'tree_row'::text, 'tree'::text])) or (a.tags ->> 'barrier'::text) = 'hedge'::text)
order by "Уч.", №;
