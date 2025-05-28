-- Перечни номеров маточных площадок

create or replace view "Бирюлёвский дендропарк"."№ площадок по ОСМ" as
with b as (
select distinct
		a.osm_id,
	    a.osm_type,
	    u."№" AS "Уч.",
	    a.tags ->> 'ref'::text "Код",
	    a.tags,
	    (((regexp_matches(a.tags ->> 'ref'::text, '\d+'::text))[1])::smallint) "№"
   from "Бирюлёвский дендропарк"."OSM ∀" a
   left join "Бирюлёвский дендропарк"."Участки" u ON st_intersects(u.geom, a.geom)
   where (a.tags ->> 'ref'::text) is not null
     and (((a.tags ->> 'barrier') is null or (a.tags ->> 'barrier'::text) <> 'gate'::text)
     and (((a.tags ->> 'natural'::text) = any (array['wood'::text, 'scrub'::text, 'tree_row'::text, 'tree'::text])) or (a.tags ->> 'barrier'::text) = 'hedge'::text)
         )
      or (a.tags ->> 'ref:start_date'::text) is not null
),
uq as (
select distinct
       "Уч.",
       "Код",
       №
  from b
order by "Уч.", №, "Код"  
)
select *, row_number() over () "id" from uq;

create view "Бирюлёвский дендропарк"."№ площадок по сверке Дмитрия" as
with b as (
select "Адрес" !~ '\*' "План 1978",
       split_part("Адрес", '×', 1)::int2 "Уч.",
       regexp_substr(replace(split_part("Адрес", '×', 2), '*', ''), '^\d+')::int2 "№",
       1::bool "сверка 2019"
from "Бирюлёвский дендропарк"."МП сверка Дмитрия" mp
)
select *
from b
where "№" is not null -- Новая экспозиция редких видов растений игнорируется
order by "Уч." asc, "№";

create view "Бирюлёвский дендропарк"."№ площадок по паспорту ОКН" as
with b as (
select distinct "Уч.",
       regexp_substr("№", '^\d+')::int2 "№"
from "Бирюлёвский дендропарк"."ОписьИзПредмОхрОКН" o
)
select *, 1::bool "пасп ОКН"
from b
order by "Уч." asc, "№";

-- Сводка нумерации маточных площадок
create view "Бирюлёвский дендропарк"."№ площадок сводка" as
select "Уч.","№", "Код",
       "пасп ОКН" is not null "пасп ОКН",
       "сверка 2019" is not null "сверка 2019",
       "Код" is not null "OSM" 
  from "Бирюлёвский дендропарк"."№ площадок по ОСМ" o
  full join "Бирюлёвский дендропарк"."№ площадок по паспорту ОКН" p
 using ("Уч.","№")
  full join  "Бирюлёвский дендропарк"."№ площадок по сверке Дмитрия" s
 using ("Уч.","№")
 order by "Уч.","№";

-- Есть расхождения
select * from "Бирюлёвский дендропарк"."№ площадок сводка" s
where 54 > s."Уч."
  and not (s."пасп ОКН" and s."сверка 2019" and s."OSM");
