create schema "Бирюлёвский дендропарк: WikiData";

create materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' || 
    urlencode(
      'SELECT ?элемент ?элементLabel ?типДорогиLabel ?№
WHERE {
  ?элемент wdt:P361 wd:Q4087179 ; p:P361 ?stn. # Бирюлёвский дендропарк     
  OPTIONAL { ?stn pq:P1545 ?№.}                # порядковый номер его части (из паспорта ОКН)
  ?элемент wdt:P31 ?типДороги .                # тип объекта
  ?типДороги wdt:P279* ?родитель.
  FILTER (?родитель IN (wd:Q34442, wd:Q5004679)) . # тип объекта восходит к дорогам или тропам
  SERVICE wikibase:label { bd:serviceParam wikibase:language "ru" . }
}'
    ) ||
    '&format=json'
  )).content::json -> 'results' -> 'bindings' j_r
),
element as (
select json_array_elements(j_r) j
  from wikidata_json
)
select j -> 'элемент' ->> 'value' "wikidata",
       j -> 'элементLabel' ->> 'xml:lang' "язык",
       j -> 'элементLabel' ->> 'value' "название",
       j -> 'типДорогиLabel' ->> 'value' "тип",
       j -> '№' ->> 'value' "№"
from element;

refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
