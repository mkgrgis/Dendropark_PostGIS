-- Получение таблицы из статьи на Википедии.
-- Административные команды, которые нужно предварительно выполнить
/*

CREATE EXTENSION file_fdw;
CREATE SERVER "Wiki дендропарк" FOREIGN DATA WRAPPER file_fdw;

*/

create schema "Бирюлёвский дендропарк: Википедия";

-- Представление, осуществляющее скачку вики-разметки из Википедии
create foreign table "Бирюлёвский дендропарк: Википедия".wget (
  content text
) server "Wiki дендропарк"
options ( program  'wget "https://ru.wikipedia.org/w/index.php?title=Бирюлёвский_дендрарий&action=edit" -qO -', format 'text', delimiter '' );

-- Формирователь реляционного табличного вида описи дендрологической коллекции
create materialized view "Бирюлёвский дендропарк: Википедия"."Флора" as
with s_agg as ( -- Слияние всех полученных текстовых данных
select string_agg(content, '
') t,
'(?<=Опись дендрологической коллекции)[^}]+}' as filter
from "Бирюлёвский дендропарк: Википедия".wget
), 
floral_t as ( -- Ракрывающаяся таблица в разделе «"Флора"»
select (regexp_match(t,  filter))[1] t 
from s_agg
),
tab_okn as ( -- Вложенная таблица из паспорта ОКН
select (regexp_match(t,  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from floral_t
),
wiki_tab as ( -- Пропускаем заголовок, читаем после «|-» с новой строки
select (regexp_matches(t,  '(?<=\|\-
\s?\|).+'))[1] t
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
create view "Бирюлёвский дендропарк: Википедия"."№№ пл. по Википедии" as
select distinct regexp_substr("Адрес", '^\d+')::int2 "Уч.",
       regexp_substr("Адрес", '(?<=×)\d+')::int2 "№",
       "Адрес"
from "Бирюлёвский дендропарк: Википедия"."Флора"
order by "Уч." asc, "№" asc;

-- Формирователь реляционного табличного вида
-- подтверждённой табличками части дендрологической коллекции
create materialized view "Бирюлёвский дендропарк: Википедия"."Таблички" as
with s_agg as ( -- Слияние всех полученных текстовых данных
select string_agg(content, '
') t,
'(?<=Список видовых табличек)[^}]+}' as filter
from "Бирюлёвский дендропарк: Википедия".wget
), 
floral_t as ( -- Ракрывающаяся таблица в разделе «"Флора"»
select (regexp_match(t,  filter))[1] t 
from s_agg
),
tab_vt as ( -- Вложенная таблица списка видовых табличек
select (regexp_matches(t,  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from floral_t
),
wiki_tab as ( -- Пропускаем заголовок, читаем после «|-» с новой строки
select (regexp_matches(t,  '(?<=\|\-
\s?\|).+'))[1] t
from tab_vt
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

-- Формирователь реляционного табличного вида
-- списка ценных видовых раскрытий
create materialized view "Бирюлёвский дендропарк: Википедия"."Ценные видовые раскрытия" as
with s_agg as ( -- Слияние всех полученных текстовых данных
select string_agg(content, '
') t,
'(?<=== Ценные видовые раскрытия ==)(.*?)(?=\|})' as filter
from "Бирюлёвский дендропарк: Википедия".wiki_wget
), 
cwr_t as ( -- Ракрывающаяся таблица в разделе «Ценные видовые раскрытия»
select (regexp_match(t,  filter))[1] t 
from s_agg
),
tab_cwr as ( -- Вложенная таблица списка видовых табличек
select (regexp_matches(t||'||}',  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from cwr_t
),
wiki_tab as ( -- Пропускаем заголовок, читаем после «|-» с новой строки
select (regexp_matches(t,  '(?<=\|\-
\s?\|).+'))[1] t
from tab_cwr
),
cortage as ( -- Переводим строки вики-разметки в набор строк
select regexp_split_to_table(t, '
\|\-
\|') c
from tab
),
arr as ( -- В каждой строке массив ячеек
select regexp_split_to_array(c, '
\|') a
from cortage
)
select a[1]::int2 "№",
       a[2] "Название",       
       split_part(regexp_replace(a[3],'\[|\]', '', 'g'), ' ', 1) "URL OSM",
       split_part(split_part(regexp_replace(a[3],'\[|\]', '', 'g'), ' ', 1), '/', -1)::int8 "Код OSM",
       split_part(split_part(regexp_replace(a[3],'\[|\]', '', 'g'), ' ', 1), '/', -2) "Тип OSM",
       split_part(regexp_replace(a[3],'\[|\]', '', 'g'), ' ', 2) "надпись для OSM URL",
       split_part(a[4], '-', 1)::float4  "обзор мин",
       split_part(a[4], '-', -1)::float4 "обзор макс",       
       a[5]::float4 "азимут"
from arr;

-- Формирователь реляционного табличного вида
-- списка аллей
create materialized view "Бирюлёвский дендропарк: Википедия".аллеи as

with s_agg as ( -- Слияние всех полученных текстовых данных
select string_agg(content, '
') t,
'(?<====== Аллеи с обсадками =====)(.*?)(?=\|})' as filter
from "Бирюлёвский дендропарк: Википедия".wget
), 
avn_t as ( -- Ракрывающаяся таблица в разделе «Ценные видовые раскрытия»
select (regexp_match(t,  filter))[1] t 
from s_agg
),
tab_avn as ( -- Вложенная таблица списка видовых табличек
select (regexp_matches(t||'||}',  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from avn_t
),
wiki_tab as ( -- Пропускаем заголовок, читаем после «|-» с новой строки
select (regexp_matches(t,  '(?<=\|\-
\s?\|).+'))[1] t
from tab_avn
),
cortage as ( -- Переводим строки вики-разметки в набор строк
select regexp_split_to_table(t, '
\s?\|\-
\s?\|') c
from wiki_tab
),
arr as ( -- В каждой строке массив ячеек
select regexp_split_to_array(c, '
\s?\|') a
from cortage
)
select a[1]::int2 "№",
       a[2] "Название",       
       a[3] "Длина",
       split_part(regexp_replace(a[4],'\[|\]', '', 'g'), '|', 1) "Вид или род wiki",
       split_part(regexp_replace(a[4],'\[|\]', '', 'g'), '|', -1) "Вид или род",       
       a[5] "Код § ОКН",
       a[6] "Примечание"       
from arr;

refresh materialized view "Бирюлёвский дендропарк: Википедия"."Флора";
refresh materialized view "Бирюлёвский дендропарк: Википедия"."Таблички";
refresh materialized view "Бирюлёвский дендропарк: Википедия"."Ценные видовые раскрытия";
