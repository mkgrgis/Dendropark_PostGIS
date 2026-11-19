create schema "Бирюлёвский дендропарк: Дмитрий";

-- Описан процесс скачки и разбора документа ods (подвид OpenDocument ODF)
-- в представления общего назначения СУБД PostgreSQL
-- разбор данных в другом файле

-- Таблица для хранения образов ods документов
create table "Бирюлёвский дендропарк: Дмитрий".ods (
	"№" serial not null primary key,
	"Время" timestamptz not null default now(),
	url text not null,
	ods bytea not null
);

-- truncate table "Бирюлёвский дендропарк: Дмитрий"."ods";
-- Запись очередного ods документа, может отвечать долго, хотя обычно в 5 секунд укладывается с запасом
set http.curlopt_timeout_msec = 200000;
insert into "Бирюлёвский дендропарк: Дмитрий"."ods" (ods, url)
with url as (select 'https://moscowparks.narod.ru/docs/explication.ods' url)
select text_to_bytea(content), url.url
from url,
     http_get(url.url);

-- Листы сохранённых ods документов, представляет соответствующие XML ветви и названия;
-- drop view "Бирюлёвский дендропарк: Дмитрий"."ODF XML листы" cascade;
create view "Бирюлёвский дендропарк: Дмитрий"."ODF XML листы" as
with xml_content as (
select "№",
       "Время",
       url,
       'content.xml' filename,
       convert_from(bytea_unzip(ods, 'content.xml'), 'UTF8')::xml xml,
       ARRAY[ARRAY['office','urn:oasis:names:tc:opendocument:xmlns:office:1.0'],
             ARRAY['table', 'urn:oasis:names:tc:opendocument:xmlns:table:1.0']
            ] odf_ns
from  "Бирюлёвский дендропарк: Дмитрий"."ods" o -- unzip
),
table_xml as (
select "№", "Время", filename, url,
       unnest(xpath('//office:body/office:spreadsheet/table:table', xml, odf_ns)) table_xml,
       unnest(xpath('//office:body/office:spreadsheet/table:table/@table:name', xml, odf_ns))::text table_name
       from xml_content
)
select "№",
       "Время",
       url,
       filename,
       row_number() over (partition by "№", filename) "№ листа",
       table_name,
       table_xml
from table_xml;

-- Свёрнутый в массив вид всех ячеек всех листов всех ods документов.
create or replace view "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки[]" as
with dc as (
select "№",
       "Время",
       url,
       "№ листа",       
       decompose_ods_table_node(table_xml) cell       
  from "Бирюлёвский дендропарк: Дмитрий"."ODF XML листы" l
), rn as (
select "№",
       "Время",
       url,
       "№ листа",
       row_number() over (partition by "№", "Время", url, "№ листа") "№ строки",
       cell       
  from dc
)
select *
  from rn  
 where cardinality(cell) > 0
  order by "№", "Время", url, "№ листа", "№ строки";
