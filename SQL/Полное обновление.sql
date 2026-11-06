-- ОБНОВЛЕНИЕ ВСЕХ ОБНОВЛЯЕМЫХ ИСТОЧНИКОВ ДАННЫХ ПО БИРЮЛЁВСКОМУ ДЕНДРОПАРКУ 

-- PastVu
refresh materialized view "Бирюлёвский дендропарк: PastVu"."∀ curl";

-- Викиданные
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Дорожно-тропиночная сеть";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: надобъект";
refresh materialized view "Бирюлёвский дендропарк: WikiData"."Элементы ОКН: типы";

-- Таблицы из статьи Википедии о Бирюлёвском дендропарке
refresh materialized view "Бирюлёвский дендропарк: Википедия"."Аллеи";
refresh materialized view "Бирюлёвский дендропарк: Википедия"."Флора";
refresh materialized view "Бирюлёвский дендропарк: Википедия"."Флористические таблички";
refresh materialized view "Бирюлёвский дендропарк: Википедия"."Ценные видовые раскрытия";

-- Экспликация Дмитрия
-- Запись очередного ods документа
insert into "Бирюлёвский дендропарк: Дмитрий"."ods" (ods, url)
with url as (select 'https://moscowparks.narod.ru/docs/explication.ods' url)
select text_to_bytea(content), url.url
from url,
     http_get(url.url);
refresh materialized view "Бирюлёвский дендропарк: Дмитрий"."ДТС группы";
refresh materialized view "Бирюлёвский дендропарк: Дмитрий"."ДТС";
refresh materialized view "Бирюлёвский дендропарк: Дмитрий"."Экспликация";

-- Викисклад
-- Отвечает долго
set http.curlopt_timeout_msec = 200000;
refresh materialized view "Бирюлёвский дендропарк: ВикиСклад"."Wikimap";

-- Паспорт ОКН
-- Состав данных не меняется

-- Проект 1941 г.
-- Состав данных не меняется

-- Проект 1964-1965 г.
-- Состав данных не меняется

-- Проект 1997 г.
-- Состав данных не меняется

-- refresh materialized view ;