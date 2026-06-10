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
-- Запись очередного ods документа
insert into "Бирюлёвский дендропарк: Дмитрий"."ods" (ods, url)
with url as (select 'https://moscowparks.narod.ru/docs/explication.ods' url)
select text_to_bytea(content), url.url
from url,
     http_get(url.url);

-- Функция создаётся от администратора, требует установки ннедоверенного языка Python_
-- обычно помещаемого в отдельном пакете ОС 
-- Создание Выполняется от администратора, позднее используется кем угодно 
create or replace function unzip_bytea_rows(zip_blob bytea)
returns table(filename text, file_data bytea)
language plpython3u as $$
import io, zipfile
buf = io.BytesIO(zip_blob)
zf = zipfile.ZipFile(buf)
for info in zf.infolist():
    if not info.is_dir():
        yield (info.filename, zf.read(info))
$$;

-- Листы сохранённых ods документов, представляет соответствующие XML ветви и названия;
create view "Бирюлёвский дендропарк: Дмитрий"."ODF XML листы" as
with unzip as
(
select unzip_bytea_rows(ods) r,
       o."№",
       o."Время",
       o.url
  from "Бирюлёвский дендропарк: Дмитрий"."ods" o
),
xml_content as ( 
select "№",
       "Время",
       url,
       (r).filename,
       convert_from((r).file_data, 'UTF8')::xml xml,
       ARRAY[ARRAY['office','urn:oasis:names:tc:opendocument:xmlns:office:1.0'],
             ARRAY['table', 'urn:oasis:names:tc:opendocument:xmlns:table:1.0']
            ] odf_ns
from unzip
where (r).filename = 'content.xml'
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
from table_xml

--drop view "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки" cascade;
-- Развёрнутый вид всех ячеек всех листов всех ods документов.
create or replace view "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки" as
with b as (
select "№",
       "Время",
       url,
       table_xml xml,
       "№ листа",
       ARRAY[ARRAY['table', 'urn:oasis:names:tc:opendocument:xmlns:table:1.0'],
             ARRAY['text', 'urn:oasis:names:tc:opendocument:xmlns:text:1.0']
            ] odf_ns
  from "Бирюлёвский дендропарк: Дмитрий"."ODF XML листы" l
),
tr as (
    select "№",
           "Время",
           url,
           "№ листа",
           odf_ns,
           unnest(xpath('//table:table-row', xml, odf_ns)) AS row_node           
    from b
  ),
tr1 as ( 
select "№",
       "Время",
       url,
       "№ листа",
       odf_ns,
       row_number() over (partition by "№", "Время", url, "№ листа") "№ строки",  
       row_node 
  from tr
),
rc as (
select "№",
       "Время",
       url,
       "№ листа",
       "№ строки",
       odf_ns,
       unnest(xpath('//table:table-cell', row_node, odf_ns)) cell_xml,
       row_node       
  from tr1
),
rc1 as (
select "№",
       "Время",
       url,
       "№ листа",
       "№ строки",
       row_node,
       cell_xml,
       ((xpath('//@table:number-columns-repeated', cell_xml, odf_ns)
        )[1])::text::int n_rep,
       array_to_string(xpath('//text:p/text()', cell_xml, odf_ns), '
') c_text
   from rc),
rc2 as (   
select "№",
       "Время",
       url,
       "№ листа",
       "№ строки",
       row_node,
       n_rep,
       unnest( array[c_text] || array_fill(null::text, array[coalesce(n_rep - 1, 0)])) txt 
  from rc1
)
select "№",
       "Время",
       url,
       "№ листа",
       "№ строки",
       row_number() over (partition by "№", "Время", url, "№ листа", "№ строки") "№ ячейки",
       row_node,
       n_rep,
       txt
  from rc2;

-- Свёрнутый в массив вид всех ячеек всех листов всех ods документов.
create or replace view "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки[]" as  
select "№",
       "Время",
       url,
       "№ листа",
       "№ строки",       
       array_agg(txt) atx       
  from "Бирюлёвский дендропарк: Дмитрий"."ODF XML ячейки"
 group by "№", "Время", url, "№ листа", "№ строки"
 order by "№", "Время", url, "№ листа", "№ строки";
