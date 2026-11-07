create schema "Бирюлёвский дендропарк: WikiData";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
create materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' ||
    urlencode(
      'SELECT DISTINCT ?картинка ?элемент ?элементLabel ?типДорогиLabel ?№ ?Категория ?основательLabel ?дата_основания ?geo WHERE {
  ?элемент wdt:P361* wd:Q4087179;
    p:P361 ?stn.
  OPTIONAL { ?stn pq:P1545 ?№. }
  OPTIONAL { ?элемент wdt:P373 ?Категория. }
  ?элемент wdt:P31 ?типДороги.
  OPTIONAL { ?элемент wdt:P112 ?основатель. }
  OPTIONAL { ?элемент wdt:P580 ?дата_основания. }
  OPTIONAL { ?элемент wdt:P18 ?картинка. }
  OPTIONAL { ?элемент wdt:P625 ?geo. }
  ?типДороги (wdt:P279*) ?родитель.
  FILTER(?родитель IN(wd:Q34442, wd:Q5004679, wd:Q174782, wd:Q3352369))
  SERVICE wikibase:label { bd:serviceParam wikibase:language "ru". }
}'
    ) ||
    '&format=json'
  )).content::json -> 'results' -> 'bindings' j_r
),
element as (
select json_array_elements(j_r) j
  from wikidata_json
)
select split_part(j -> 'элемент' ->> 'value', '/', -1) "Q",
       j -> 'элементLabel' ->> 'xml:lang' "язык",
       j -> 'элементLabel' ->> 'value' "название",
       j -> 'типДорогиLabel' ->> 'value' "тип",
       (j -> '№' ->> 'value')::semver "№",
       j -> 'Категория' ->> 'value' "Категория",
       j -> 'картинка' ->> 'value' "Изображение",
       j -> 'элемент' ->> 'value' "wikidata",
       j -> 'основательLabel' ->> 'value' "Основатель",
       j -> 'дата_основания' ->> 'value' "Дата основания",
       ST_GeomFromText(j -> 'geo' ->> 'value') "wkt"
from element
order by "№", "название";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: типы";
create materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: типы" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' ||
    urlencode(
      'SELECT ?элемент ?типLabel ?тип ?№ WHERE {
  ?элемент wdt:P361* wd:Q4087179;
    p:P361 ?stn.
  ?stn pq:P1545 ?№.
  ?элемент wdt:P31 ?тип.
    SERVICE wikibase:label { bd:serviceParam wikibase:language "ru". }
}
order by ?№'
    ) ||
    '&format=json'
  )).content::json -> 'results' -> 'bindings' j_r
),
element as (
select json_array_elements(j_r) j
  from wikidata_json
)
select split_part(j -> 'элемент' ->> 'value', '/', -1) "Объект Q",
       j -> 'типLabel' ->> 'value' "Тип",
       split_part(j -> 'тип' ->> 'value', '/', -1) "Тип Q",
       (j -> '№' ->> 'value') "№ в ОКН",
       j -> 'элемент' ->> 'value' "Объект URL",
       j -> 'тип' ->> 'value' "Тип URL"
from element
order by "№ в ОКН", "Объект Q";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: надобъект";
create materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: надобъект" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' ||
    urlencode(
      'SELECT ?элемент ?элементLabel ?№ ?в_составе ?в_составеLabel WHERE {
  ?элемент (wdt:P361*) wd:Q4087179;
    p:P361 ?stn.
  ?stn pq:P1545 ?№.
  ?элемент wdt:P361 ?в_составе.
  SERVICE wikibase:label { bd:serviceParam wikibase:language "ru". }
}
ORDER BY (?№)'
    ) ||
    '&format=json'
  )).content::json -> 'results' -> 'bindings' j_r
),
element as (
select json_array_elements(j_r) j
  from wikidata_json
)
-- ?элемент ?элементLabel ?№ ?картинка ?категория ?в_составе
select split_part(j -> 'элемент' ->> 'value', '/', -1) "Объект Q",
       split_part(j -> 'в_составе' ->> 'value', '/', -1) "Надобъект Q",
       j -> 'элементLabel' ->> 'value' "Объект",
       j -> 'в_составеLabel' ->> 'value' "Надобъект",
       (j -> '№' ->> 'value') "№ в ОКН",
       j -> 'элемент' ->> 'value' "Объект URL",
       j -> 'в_составе' ->> 'value' "Надобъект URL"
from element
order by "№ в ОКН", "Объект Q";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН";
create materialized view "Б1ирюлёвский дендропарк: WikiData"."Элементы ОКН" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' ||
    urlencode(
      'SELECT ?элемент ?элементLabel ?№ ?картинка ?категория ?в_составе WHERE {
  ?элемент (wdt:P361*) wd:Q4087179;
    p:P361 ?stn.
  ?stn pq:P1545 ?№.
  OPTIONAL { ?элемент wdt:P373 ?категория. }
  OPTIONAL { ?элемент wdt:P18 ?картинка. }
  SERVICE wikibase:label { bd:serviceParam wikibase:language "ru". }
}
ORDER BY (?№)'
    ) ||
    '&format=json'
  )).content::json -> 'results' -> 'bindings' j_r
),
element as (
select json_array_elements(j_r) j
  from wikidata_json
)
-- ?элемент ?элементLabel ?№ ?картинка ?категория ?в_составе
select split_part(j -> 'элемент' ->> 'value', '/', -1) "Объект Q",
       j -> 'элементLabel' ->> 'value' "Объект",
       (j -> '№' ->> 'value') "№ в ОКН",
       j -> 'элемент' ->> 'value' "Объект URL",
       j -> 'картинка' ->> 'value' "Картинка",
       j -> 'категория' ->> 'value' "Категория"
from element
order by "№ в ОКН", "Объект Q";

create or replace view "Бирюлёвский дендропарк: WikiData"."Аллеи ОКН" as
select e.*
  from "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: надобъект" n
 inner join "Бирюлёвский дендропарк: WikiData"."Элементы ОКН" e
 using ("Объект Q")
 where n."Надобъект" in (
       'Аллеи 1938-1960-х годов включая направление и двухрядную обсадку',
       'Граничная обсадка 1938-1960-х годов' );

drop materialized view "Бирюлёвский дендропарк: WikiData"."Водоёмы";
create materialized view "Бирюлёвский дендропарк: WikiData"."Водоёмы" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' ||
    urlencode(
      'SELECT DISTINCT ?элемент ?элементLabel ?№ ?картинка ?категория ?классLabel WHERE {
  ?элемент (wdt:P361*) wd:Q4087179;
     p:P361 ?stn.
  ?элемент wdt:P31 ?класс.
  ?класс wdt:P279* wd:Q15324.
  OPTIONAL { ?stn pq:P1545 ?№. }
  OPTIONAL { ?элемент wdt:P373 ?категория. }
  OPTIONAL { ?элемент wdt:P18 ?картинка. }
  #?элемент wdt:P361 ?в_составе.
  SERVICE wikibase:label { bd:serviceParam wikibase:language "ru". }
}
ORDER BY (?№)'
    ) ||
    '&format=json'
  )).content::json -> 'results' -> 'bindings' j_r
),
element as (
select json_array_elements(j_r) j
  from wikidata_json
)
-- ?элемент ?элементLabel ?№ ?картинка ?категория ?в_составе
select split_part(j -> 'элемент' ->> 'value', '/', -1) "Объект Q",
       j -> 'элементLabel' ->> 'value' "Объект",
       (j -> '№' ->> 'value') "№ в ОКН",
       j -> 'элемент' ->> 'value' "Объект URL",
       j -> 'картинка' ->> 'value' "Картинка",
       j -> 'категория' ->> 'value' "Категория",
       j -> 'класс' ->> 'value' "Класс объекта"
from element
order by "№ в ОКН", "Объект Q";

refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: типы";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: надобъект";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Водоёмы";