create schema "Бирюлёвский дендропарк: WikiData";

create materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' || 
    urlencode(
      'SELECT ?картинка ?элемент ?элементLabel ?типДорогиLabel ?№ ?Категория
WHERE {
  ?элемент wdt:P361 wd:Q4087179 ; p:P361 ?stn. # Бирюлёвский дендропарк     
  OPTIONAL { ?stn pq:P1545 ?№. }               # порядковый номер его части (из паспорта ОКН)
  OPTIONAL { ?элемент wdt:P373 ?Категория. }   # категория ВикиСклада
  ?элемент wdt:P31 ?типДороги.                 # тип объекта
  ?типДороги wdt:P279* ?родитель.
  OPTIONAL { ?элемент wdt:P18 ?картинка. }
  FILTER (?родитель IN (wd:Q34442, wd:Q5004679, wd:Q174782)) . # тип объекта восходит к дорогам, тропам или площадям
  SERVICE wikibase:label { bd:serviceParam wikibase:language "ru" . }
} '
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
       j -> 'элемент' ->> 'value' "wikidata"
from element
order by "№", "название";

refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
