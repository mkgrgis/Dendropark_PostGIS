-- Получение таблицы из статьи на Википедии.
-- Административные команды, которые нужно предварительно выполнить
/*
CREATE EXTENSION pg_wget;
*/

create schema "Бирюлёвский дендропарк: Википедия";

-- Представление, осуществляющее скачку вики-разметки из Википедии
create materialized view "Бирюлёвский дендропарк: Википедия".wget as 
select pg_wget('https://ru.wikipedia.org/w/index.php?title=Бирюлёвский_дендрарий&action=raw') wikitext, now() dt;
-- drop materialized view "Бирюлёвский дендропарк: Википедия".wget cascade

create view "Бирюлёвский дендропарк: Википедия"."Главы" as
with input_data as (
    -- Замените этот CTE на выборку из вашей таблицы
    select  wikitext
     from "Бирюлёвский дендропарк: Википедия".wget
),
lines as (
    -- Разбиваем викитекст на строки с сохранением их исходного порядка
    select 
        ordinality as line_num,
        line
    from input_data,
    lateral regexp_split_to_table(wikitext, '\r?\n') with ordinality as t(line, ordinality)
),
parsed_headers as (
    -- Определяем уровень заголовка (2, 3 или 4) и очищаем его текст от знаков '='
    select 
        line_num,
        line,
        case 
            when line ~ '^={4}[^=].*[^=]={4}\s*$' then 4
            when line ~ '^={3}[^=].*[^=]={3}\s*$' then 3
            when line ~ '^={2}[^=].*[^=]={2}\s*$' then 2
            else 0
        end as h_level,
        case 
            when line ~ '^={2,4}[^=].*[^=]={2,4}\s*$' 
            then trim(regexp_replace(line, '^={2,4}\s*(.*?)\s*={2,4}\s*$', '\1'))
            else null
        end as h_title
    from lines
),
grouped_blocks as (
    -- Каждое появление заголовка начинает новый логический блок текста
    select 
        *,
        count(nullif(h_level, 0)) over (order by line_num) as block_id
    from parsed_headers
),
aggregated_blocks as (
    -- Объединяем строки текста внутри каждого блока
    select 
        block_id,
        max(h_level) as h_level,
        max(h_title) as h_title,
        trim(both E'\n' from string_agg(
            case when h_level = 0 then line end, 
            E'\n' order by line_num
        )) as inner_wikitext
    from grouped_blocks
    group by block_id
),
hierarchy_markers as (
    -- Формируем сквозные группы для отслеживания вложенности
    select 
        *,
        count(case when h_level = 2 then 1 end) over (order by block_id) as ch_grp,
        count(case when h_level in (2, 3) then 1 end) over (order by block_id) as sub_grp,
        count(case when h_level in (2, 3, 4) then 1 end) over (order by block_id) as subsub_grp
    from aggregated_blocks
)
select 
    ch_grp || '.' ||
    dense_rank() over (partition by ch_grp order by sub_grp) - 1 || '.' ||
    dense_rank() over (partition by sub_grp order by subsub_grp) - 1 as "№",
    max(case when h_level = 2 then h_title end) over (partition by ch_grp) as "Глава",
    max(case when h_level = 3 then h_title end) over (partition by sub_grp) as "Подглава",
    max(case when h_level = 4 then h_title end) over (partition by subsub_grp) as "Пункт",
    coalesce(inner_wikitext, '') as "Викитекст"
from hierarchy_markers
where trim (inner_wikitext) <> ''
order by block_id;

-- Формирователь реляционного табличного вида описи дендрологической коллекции
create view "Бирюлёвский дендропарк: Википедия"."Флора" as
with floral_t as ( -- Ракрывающаяся таблица в разделе «"Флора"»
select (regexp_match("Викитекст", '(?<=Опись дендрологической коллекции)[^}]+}'))[1] t
from "Бирюлёвский дендропарк: Википедия"."Главы"
where "Глава" = 'Флора'
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
select split_part(split_part(a[1], '&', 1), '<', 1)::text "Адрес",
       split_part(a[1], '×', 1)::int2 "Уч.",
       split_part(split_part(a[1], '×', 2), '(', 1)::int2 "№",
       split_part(split_part(split_part(a[1], '×', 2), '&', 1), '<', 1) "№_",
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
with orig as (
select distinct regexp_substr("Адрес", '^\d+')::int2 "Уч.",
       regexp_substr("Адрес", '(?<=×)\d+')::int "№ в ОКН",
       -- regexp_substr("Адрес", '(?<=×\d+\().+') ~ '’' "штрих",
       regexp_substr("Адрес", '(?<=×\d+\()\d+’?(?=\))') "№денд",
       "Адрес" "Адрес₀"
  from "Бирюлёвский дендропарк: Википедия"."Флора"
  -- coalesce (regexp_substr("Адрес", '(?<=×\d+\()\d+(?=’\))'), regexp_substr("Адрес", '(?<=×)\d+'))::int2 "№",
)
select "Уч.",
       coalesce("№денд", "№ в ОКН"::text) "№",
       regexp_substr(coalesce("№денд", "№ в ОКН"::text), '^\d+')::int2 "№₀",
       "№денд",
       "Уч." || '×' || coalesce("№денд", "№ в ОКН"::text) "Адрес",
       "Уч." || '×' || "№ в ОКН"::text "Адрес в ОКН"
  from orig
 order by "Уч." asc, "№₀" asc, "№" asc;

-- Формирователь реляционного табличного вида
-- подтверждённой табличками части дендрологической коллекции
create view "Бирюлёвский дендропарк: Википедия"."Флористические таблички" as
with floral_t as ( -- Ракрывающаяся таблица в разделе «"Флора"»
select (regexp_match("Викитекст", '(?<=Список видовых табличек)[^}]+}'))[1] t
from "Бирюлёвский дендропарк: Википедия"."Главы"
where "Глава" = 'Флора'
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
       --a[2] "Изображение",
       split_part(regexp_replace(regexp_replace(a[2], '^\[\[', ''), '\]\]$', ''), '|', 1) "Файл",
       split_part(regexp_replace(regexp_replace(a[2], '^\[\[', ''), '\]\]$', ''), '|', 2) "Флаг файла",
       replace(split_part(regexp_replace(regexp_replace(a[2], '^\[\[', ''), '\]\]$', ''), '|', 3), '&amp;', '&') "Название",
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
create view "Бирюлёвский дендропарк: Википедия"."Ценные видовые раскрытия" as
with cwr_t as ( -- Ракрывающаяся таблица в разделе «Ценные видовые раскрытия»
select "Викитекст" t
from "Бирюлёвский дендропарк: Википедия"."Главы"
where "Глава" = 'Ценные видовые раскрытия'
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
from wiki_tab
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
       a[5]::float4 "азимут",
       a[4] α
  from arr;

-- Формирователь реляционного табличного вида
-- списка аллей
create view "Бирюлёвский дендропарк: Википедия"."Аллеи" as
with avn_t as ( -- Ракрывающаяся таблица в разделе «Ценные видовые раскрытия»
select (regexp_match("Викитекст", '(?<====== Аллеи с обсадками =====)(.*?)(?=\|})'))[1] t
from "Бирюлёвский дендропарк: Википедия"."Главы"
where "Глава" = 'Флора'
),
tab_avn as ( -- Вложенная таблица списка видовых табличек
select (regexp_matches(t||'||}',  '(?<={\|)[\s\S]+(?=\|})'))[1] t
from avn_t
where t is not null
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
       trim(unnest(string_to_array(a[5], ','))) "Пункт в ОКН",
       regexp_substr(trim(unnest(string_to_array(a[5], ','))), '.*(?=\.)') "№ в ОКН",
       a[6] "Примечание"
from arr;

refresh materialized view "Бирюлёвский дендропарк: Википедия".wget;
-- конец