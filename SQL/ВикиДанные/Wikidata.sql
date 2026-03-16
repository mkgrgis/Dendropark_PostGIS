create schema "Бирюлёвский дендропарк: WikiData";

create materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' || 
    urlencode(
      'SELECT ?элемент ?элементLabel ?типДороги ?типДорогиLabel
WHERE {
  ?элемент wdt:P361 wd:Q4087179 .         # Бирюлёвский дендропарк
  ?элемент wdt:P31 ?типДороги .            # тип объекта
  ?типДороги wdt:P279* wd:Q34442 .          # подкласс дороги (road)
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
       j -> 'типДорогиLabel' ->> 'value' "тип"
from element;

refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";