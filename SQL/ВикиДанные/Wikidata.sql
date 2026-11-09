create schema "Бирюлёвский дендропарк: WikiData";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" cascade;
create materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' ||
    urlencode(
      'SELECT DISTINCT ?картинка ?элемент ?элементLabel ?типДорогиLabel ?№ ?Категория ?основательLabel ?дата_основания ?geo ?ПолнаяАллея WHERE {
  ?элемент wdt:P361* wd:Q4087179;
    p:P361 ?stn.
  OPTIONAL { ?stn pq:P1545 ?№. }
  OPTIONAL { ?элемент wdt:P373 ?Категория. }
  ?элемент wdt:P31 ?типДороги.
  OPTIONAL { ?элемент wdt:P112 ?основатель. }
  OPTIONAL { ?элемент wdt:P580 ?дата_основания. }
  OPTIONAL { ?элемент wdt:P18 ?картинка. }
  OPTIONAL { ?элемент wdt:P625 ?geo. }
  OPTIONAL { ?элемент wdt:P361 ?ПолнаяАллея.
             ?ПолнаяАллея wdt:P31 wd:Q207934.
           }
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
       j -> 'основательLabel' ->> 'value' "Основатель",
       j -> 'дата_основания' ->> 'value' "Дата основания",
       ST_GeomFromText(j -> 'geo' ->> 'value') "wkt",
       split_part(j -> 'ПолнаяАллея' ->> 'value', '/', -1) "Q полной аллеи",
       replace(j -> 'элемент' ->> 'value', 'http://', 'https://') "Объект URL",
       replace(j -> 'картинка' ->> 'value', 'http://', 'https://') "Картинка"
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
       replace(j -> 'элемент' ->> 'value', 'http://', 'https://') "Объект URL",
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
       replace(j -> 'элемент' ->> 'value', 'http://', 'https://') "Объект URL",
       j -> 'в_составе' ->> 'value' "Надобъект URL"
from element
order by "№ в ОКН", "Объект Q";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН";
create materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН" as
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
       replace(j -> 'элемент' ->> 'value', 'http://', 'https://') "Объект URL",
       replace(j -> 'картинка' ->> 'value', 'http://', 'https://') "Картинка",
       j -> 'категория' ->> 'value' "Категория"
from element
order by "№ в ОКН", "Объект Q";

drop view "Бирюлёвский дендропарк: WikiData"."Аллеи ОКН" cascade;
create or replace view "Бирюлёвский дендропарк: WikiData"."Аллеи ОКН" as
select d.*
  from "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" d
 where "№" is not null or "Q полной аллеи" is not null;

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
       replace(j -> 'элемент' ->> 'value', 'http://', 'https://') "Объект URL",
       replace(j -> 'картинка' ->> 'value', 'http://', 'https://') "Картинка",
       j -> 'категория' ->> 'value' "Категория",
       j -> 'класс' ->> 'value' "Класс объекта"
from element
order by "№ в ОКН", "Объект Q";

refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: типы";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: надобъект";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Водоёмы";