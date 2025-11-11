-- Получение таблицы из статьи на Википедии.
-- Административные команды, которые нужно предварительно выполнить
/*

CREATE EXTENSION file_fdw;
CREATE SERVER "Wiki дендропарк" FOREIGN DATA WRAPPER file_fdw;

*/
-- Представление, осуществляющее скачку вики-разметки из Википедии
create foreign table "Бирюлёвский дендропарк".wiki_wget (
  content text
) server "Wiki дендропарк"
options ( program  'wget "https://ru.wikipedia.org/w/index.php?title=Бирюлёвский_дендрарий&action=edit" -qO -', format 'text', delimiter '' );

-- Формирователь реляционного табличного вида описи дендрологической коллекции
create materialized view "Бирюлёвский дендропарк".wiki_флора as
with s_agg as ( -- Слияние всех полученных текстовых данных
select string_agg(content, '
') t,
'(?<=Опись дендрологической коллекции)[^}]+}' as filter
from "Бирюлёвский дендропарк".wiki_wget
), 
floral_t as ( -- Ракрывающаяся таблица в разделе «Флора»
select (regexp_match(t,  filter))[1] t 
from s_agg
),
tab_okn as ( -- Вложенная таблица из паспорта ОКН
select (regexp_match(t,  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from floral_t
),
wiki_tab as ( -- Пропускаем заголовок, читаем после «|-» с новой строки
select (regexp_matches(t,  '(?<=\|\-
\|).+'))[1] t
from tab_okn
),
cortage as ( -- Переводим строки вики-разметки в набор строк
select regexp_split_to_table(t, '
\|\-
\|') c
from wiki_tab
),
arr as ( -- В каждой строке массив ячеек
select regexp_split_to_array(c, '
\|') a
from cortage
)
select split_part(a[1], '&', 1)::text "Адрес",
       split_part(a[1], '×', 1)::int2 "Уч.",
       split_part(split_part(a[1], '×', 2), '(', 1)::int2 "№",
       split_part(split_part(a[1], '×', 2), '&', 1) "№_",
       length(a[2]) > 1 "Утрата",
       a[3]::int2 "Видов",
       split_part(regexp_replace(a[4],'\[|\]', '', 'g'), '|', 1) "Вид или род wiki",
       split_part(regexp_replace(a[4],'\[|\]', '', 'g'), '|', -1) "Вид или род",
       split_part(regexp_replace(a[5],'\[|\]', '', 'g'), ' ', 1) "OSM URL",
       a[6] "обсадка",
       a[7] "сохранность",
       a[2] a2,
       a[4] a4,
       a[5] a5
from arr;

-- Список номеров маточных площадок
CREATE VIEW "Бирюлёвский дендропарк"."№№ пл. по Википедии" as
SELECT DISTINCT regexp_substr("Адрес", '^\d+')::int2 "Уч.",
       regexp_substr("Адрес", '(?<=×)\d+')::int2 "№",
       "Адрес"
FROM "Бирюлёвский дендропарк".wiki_флора
order by "Уч." asc, "№" asc;

refresh materialized view "Бирюлёвский дендропарк".wiki_флора;

-- Формирователь реляционного табличного вида
-- подтверждённой табличками части дендрологической коллекции
create materialized view "Бирюлёвский дендропарк".wiki_таблички as
with s_agg as ( -- Слияние всех полученных текстовых данных
select string_agg(content, '
') t,
'(?<=Список видовых табличек)[^}]+}' as filter
from "Бирюлёвский дендропарк".wiki_wget
), 
floral_t as ( -- Ракрывающаяся таблица в разделе «Флора»
select (regexp_match(t,  filter))[1] t 
from s_agg
),
tab_okn as ( -- Вложенная таблица списка видовых табличек
select (regexp_matches(t,  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from floral_t
),
wiki_tab as ( -- Пропускаем заголовок, читаем после «|-» с новой строки
select (regexp_matches(t,  '(?<=\|\-
\|).+'))[1] t
from tab_okn
),
cortage as ( -- Переводим строки вики-разметки в набор строк
select regexp_split_to_table(t, '
\|\-
\|') c
from wiki_tab
),
arr as ( -- В каждой строке массив ячеек
select regexp_split_to_array(c, '
\|') a
from cortage
)
select case when a[1] ~ '×' then split_part(split_part(a[1], '&', 1), '
', 1)::text else null end "Адрес",
       case when a[1] ~ '×' then split_part(a[1], '×', 1)::int2 else null end  "Уч.",
       case when a[1] ~ '×' then regexp_substr(a[1], '(?<=×)\d+')::int2 else null end "№",
       case when a[1] !~ '×' then a[1] else null end "Указание на аллею",
       split_part(split_part(split_part(a[1], '×', 2), '&', 1), '
', 1) "№_",
       a[2] "Изображение",
       a[3] "lat",       
       split_part(regexp_replace(a[4],'\[|\]', '', 'g'), '|', 1) "Вид или род wiki",
       split_part(regexp_replace(a[4],'\[|\]', '', 'g'), '|', -1) "Вид или род",       
       a[5] "ОКН",
       split_part(regexp_replace(a[6],'\[|\]', '', 'g'), ' ', 1) "OSM URL",       
       a[7] "обсадка",
       a[8] "примечание",
       a[1] "a1"
from arr;

refresh materialized view "Бирюлёвский дендропарк".wiki_таблички;