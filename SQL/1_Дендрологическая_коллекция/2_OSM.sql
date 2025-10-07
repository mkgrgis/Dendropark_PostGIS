-- Перечень уникальных маточных площадок на ОСМ
create or replace view "Бирюлёвский дендропарк"."№№ пл. по ОСМ" as
with уч as ( -- выясняем номер участка всех объектов, объект должен целиком находиться на участке
select a.*,
	   u."№" AS "Уч."
  from "Бирюлёвский дендропарк"."OSM ∀" a
  left join "Бирюлёвский дендропарк"."Участки" u
	on st_within(a.geom, u.geom)
),
ref as ( -- фильтрация того что является маточными площадками и
-- формирования обозначния из № участка, обозначния площадки и её сортировочного №
select distinct
	   a.osm_id,
	   a.osm_type,
	   a.tags,
	   "Уч.",
	   (((regexp_matches(tags ->> 'ref', '\d+'))[1])::smallint) "№",
	   tags ->> 'ref' "ref"
  from уч a   
 where (a.tags ->> 'ref:start_date') is not null -- обозначение датировано, либо
	or ((a.tags ->> 'ref') is not null -- обозначение есть и
		and ((a.tags ->> 'natural') = any (array['wood', 'scrub', 'tree_row', 'tree', 'shurb'])
			 or (a.tags ->> 'barrier') = 'hedge'
			) -- деревья или кусты или куст или посадка-линия или живая изгородь и при этом
		and (
			 coalesce(a.tags ->> 'barrier', '') <> 'gate'
			) -- не ворота
	   )
),
маточные_площадки as (
select "Уч.",
	   "№",
	   "ref",
	   "№"::text = "ref" "из ОКН",
	   count(osm_type || '/' || osm_id) over (partition by "Уч.", "№")::int2 "объектов OSM",
	   osm_type,
	   osm_id,
	   'https://openstreetmap.org/'|| osm_type || '/' || osm_id "URL",
	   tags - 'ref' t
  from ref
order by "Уч." asc, "№" asc, ref asc
)
select row_number() over ()::int2 "id",
	   *
  from маточные_площадки;

-- OSM URL для каждой маточной площадки, представленной одним объектом OSM
create view "Бирюлёвский дендропарк"."Маточные площадки OSM URL" as
select distinct true "ОСМ",	   
	   "Уч.",
	   "№",
	   "ref",
	   "из ОКН",
	   "объектов OSM",
	   case when "объектов OSM" = 1 then "URL" else null end "URL"
  from "Бирюлёвский дендропарк"."№№ пл. по ОСМ";

-- Список видов по OSM
create view "Бирюлёвский дендропарк"."ОписьИзOSM" as
with уч as ( -- выясняем номер участка всех объектов, объект должен целиком находиться на участке
select a.*,
	   u."№" AS "Уч."
  from "Бирюлёвский дендропарк"."OSM ∀" a
  left join "Бирюлёвский дендропарк"."Участки" u
	on st_within(a.geom, u.geom)
),
ref as ( -- фильтрация того что является маточными площадками и
-- формирования обозначния из № участка, обозначния площадки и её сортировочного №
select distinct
	   a.osm_id,
	   a.osm_type,
	   a.tags,
	   "Уч.",
	   (((regexp_matches(tags ->> 'ref', '\d+'))[1])::smallint) "№",
	   tags ->> 'ref' "ref"
  from уч a   
 where (a.tags ->> 'ref:start_date') is not null -- обозначение датировано, либо
	or ((a.tags ->> 'ref') is not null -- обозначение есть и
		and ((a.tags ->> 'natural') = any (array['wood', 'scrub', 'tree_row', 'tree', 'shurb'])
			 or (a.tags ->> 'barrier') = 'hedge'
			) -- деревья или кусты или куст или посадка-линия или живая изгородь и при этом
		and (
			 coalesce(a.tags ->> 'barrier', '') <> 'gate'
			) -- не ворота
	   )
),
маточные_площадки as (



with виды as (
select distinct 
	   m.*,
	   unnest(string_to_array(a.tags ->> 'taxon', ';')) AS taxon,
	   coalesce(cardinality(string_to_array(a.tags ->> 'taxon', ';')),
			    cardinality(string_to_array(a.tags ->> 'genus', ';'))) AS "видов на посадке",
	   unnest(string_to_array(a.tags ->> 'taxon:ru', ';')) AS "вид",
	   unnest(string_to_array(a.tags ->> 'genus', ';')) AS genus,
	   unnest(string_to_array(a.tags ->> 'genus:ru', ';')) AS "род"
  from "Бирюлёвский дендропарк"."OSM ∀" a 
  left join "Бирюлёвский дендропарк"."Участки" u ON st_within(a.geom, u.geom)
  left join "Бирюлёвский дендропарк"."№№ пл. по ОСМ" m
	on m."Уч." =  u."№"
   and m."Код" = a.tags ->> 'ref'
 where (a.tags ->> 'ref') is not null
   and ((a.tags ->> 'barrier') is null or (a.tags ->> 'barrier') <> 'gate')
   and (((a.tags ->> 'natural') = any (array['wood', 'scrub', 'tree_row', 'tree'])) or (a.tags ->> 'barrier') = 'hedge')
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
