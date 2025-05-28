CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Видовые таблички по OSM"
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

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк"."Видовые таблички по WikiMAp"
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


-- Сверка видового состава

create view "Бирюлёвский дендропарк"."Виды по OSM" as
with виды as (
select distinct 
	m.*,
	unnest(string_to_array(a.tags ->> 'taxon'::text, ';'::text)) AS taxon,
    coalesce(cardinality(string_to_array(a.tags ->> 'taxon'::text, ';'::text)),
             cardinality(string_to_array(a.tags ->> 'genus'::text, ';'::text))) AS "видов на посадке",
    unnest(string_to_array(a.tags ->> 'taxon:ru'::text, ';'::text)) AS "вид",
    unnest(string_to_array(a.tags ->> 'genus'::text, ';'::text)) AS genus,
    unnest(string_to_array(a.tags ->> 'genus:ru'::text, ';'::text)) AS "род"
   from "Бирюлёвский дендропарк"."OSM ∀" a 
   left join "Бирюлёвский дендропарк"."Участки" u ON st_intersects(u.geom, a.geom)
   left join "Бирюлёвский дендропарк"."№ площадок по ОСМ" m
     on m."Уч." =  u."№"
    and m."Код" = a.tags ->> 'ref'
   where (a.tags ->> 'ref'::text) is not null
     and ((a.tags ->> 'barrier') is null or (a.tags ->> 'barrier'::text) <> 'gate'::text)
     and (((a.tags ->> 'natural'::text) = any (array['wood'::text, 'scrub'::text, 'tree_row'::text, 'tree'::text])) or (a.tags ->> 'barrier'::text) = 'hedge'::text)
order by "Уч.", №, "Код"
)
select distinct
       "Уч.", "Код", №, id,
	   coalesce(taxon, genus) taxon,
       "видов на посадке",
       coalesce(вид, род) вид,
       coalesce(genus, regexp_substr(taxon, '^\S+\s')) genus,
       coalesce(род, regexp_substr(вид, '^\S+\s')) род
from виды
order by "Уч.", №, "Код";

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

create view "Бирюлёвский дендропарк"."Виды по паспорту ОКН" as
with b as (
select m."Уч.",
       split_part(m."№", '(', 1)::int2 "№",
       split_part(m."№", '(', 2) "№+",
       m.t like '%трачен%' "Утрата",
       regexp_replace(m.t, '^(У|у)трачен[аоы]?\:?\s', '') t
  from "Бирюлёвский дендропарк"."ОписьИзПредмОхрОКН" m
),
c as  (
 select "Уч.",
        "№",
        case when split_part("№+", ')', 1) = '' then NULL
             else split_part("№+", ')', 1)
         end ::varchar(3) "спец №",
        "Утрата",
        cardinality(regexp_split_to_array(t, ',\s?'))::int2 "Видов на площадке",
        unnest(regexp_split_to_array(t, ',\s?')) "Вид или род"
 from b
)
select "Уч.", "№", "Утрата", "Видов на площадке", "Вид или род"
from c;

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
   left join "Бирюлёвский дендропарк"."Участки" u ON st_intersects(u.geom, a.geom)
   left join "Бирюлёвский дендропарк"."№ площадок по ОСМ" m
     on m."Уч." =  u."№"
    and m."Код" = a.tags ->> 'ref'
   where (a.tags ->> 'ref'::text) is not null
     and ((a.tags ->> 'barrier') is null or (a.tags ->> 'barrier'::text) <> 'gate'::text)
     and (((a.tags ->> 'natural'::text) = any (array['wood'::text, 'scrub'::text, 'tree_row'::text, 'tree'::text])) or (a.tags ->> 'barrier'::text) = 'hedge'::text)
order by "Уч.", №, "Код";
