create schema "Бирюлёвский дендропарк: WikiData";

drop materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
create materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть" as
with wikidata_json as (
select
  (http_get(
    'https://query.wikidata.org/sparql?query=' || 
    urlencode(
      'SELECT ?картинка ?элемент ?элементLabel ?типДорогиLabel ?№ ?Категория ?основательLabel ?дата_основания WHERE {
  ?элемент wdt:P361 wd:Q4087179;
    p:P361 ?stn.
  OPTIONAL { ?stn pq:P1545 ?№. }
  OPTIONAL { ?элемент wdt:P373 ?Категория. }
  ?элемент wdt:P31 ?типДороги.
  OPTIONAL { ?элемент wdt:P112 ?основатель. }
  OPTIONAL { ?элемент wdt:P580 ?дата_основания. }
  OPTIONAL { ?элемент wdt:P18 ?картинка. }
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
       j -> 'дата_основания' ->> 'value' "Дата основания"
from element
order by "№", "название";

refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";