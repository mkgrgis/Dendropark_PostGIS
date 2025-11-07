


-- Сверка видового состава



create view "Бирюлёвский дендропарк"."Виды по сверке Дмитрия" as
-- Регулярный вид
with b as (
select "Адрес" ~ '\*' "OSM",
       "Адрес" !~ '\*' "План 1978",
       split_part("Адрес", '×', 1)::int2 "Уч.",
       regexp_substr(replace(split_part("Адрес", '×', 2), '*', ''), '^\d+')::int2 "№",
       split_part("Адрес", '×', 3) "№доп",
       "Флаг",
       unnest(regexp_split_to_array(mp."Растения", ';\s?')) "Вид или род"
from "Бирюлёвский дендропарк"."МП сверка Дмитрия" mp
)
select "OSM",
       "План 1978",
       "Уч.",
       "№",
       "№доп",
       "Флаг",
       regexp_replace("Вид или род", '\^|\*', '') "Вид или род",
       "Вид или род" ~ '\*' "Утрата",
       "Вид или род" ~ '\^' "После 2020"
from b
order by "Уч." asc, "№", "№доп";



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
