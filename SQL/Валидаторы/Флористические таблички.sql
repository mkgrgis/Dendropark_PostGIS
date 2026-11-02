refresh materialized view "Бирюлёвский дендропарк: Википедия"."Флористические таблички";

-- Числа табличек по разным источникам
select count (*) число, 'OSM' тип
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички" o
 union all
select count (*) число, 'ВикиСклад' тип
  from "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички"
union all
select count (*) число, 'Википедия' тип
  from "Бирюлёвский дендропарк: Википедия"."Флористические таблички";

-- Полностью комплектные случаи, таблички представлены везде
-- 149 табличек представляют флору площадок и аллей 
select o.osm_id is not null "OSM",
       wc.pageid is not null "Викисклад",
       (wp."Адрес" is not null or wp."Указание на аллею" is not null) "Википедия",
       wp."Адрес" is not null "флора площадки", -- опущенный флаг указывает на флору аллеи
       o.название,
       o.tags ->> 'was:tourism'::text = 'information' "Демонтирована",       
       round(ST_Distance(wc.φλ₁::geography, o.geom::geography)::numeric, 1) "От фото до ОСМ точки",
       round(ST_Distance(wc.φλ₀::geography, o.geom::geography)::numeric, 1) "От фотографа до ОСМ точки",
       'https://openstreetmap.org/'|| osm_type || '/' || osm_id "OSM URL",
       wc."URL" "ВикиСклад URL",
       wp."Адрес",
       o.geom "φλ OSM",
       wc.φλ₁,
       wc.φλ₀
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички" o
  full outer join "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички" wc
    on wc.title = o.tags ->> 'wikimedia_commons'
  full outer join "Бирюлёвский дендропарк: Википедия"."Флористические таблички" wp
    on wp."Файл" = o.tags ->> 'wikimedia_commons'
 where o.osm_id is not null and wc.pageid is not null and (wp."Адрес" is not null or wp."Указание на аллею" is not null);

-- Некомплектные случаи: 1 дубль фото на Викискладе + 1 табличка образца 1962 года + OSM плакаты о растениях
select o.osm_id is not null "OSM",
       wc.pageid is not null "Викисклад",
       wp."Адрес" is not null "Википедия",
       o.название,
       wc.title,
       wp."Файл",
       o.tags ->> 'wikimedia_commons' "OSM файл",
       wp."Указание на аллею",
       o.tags ->> 'was:tourism'::text = 'information' "Демонтирована",       
       round(ST_Distance(wc.φλ₁::geography, o.geom::geography)::numeric, 1) "От фото до ОСМ точки",
       round(ST_Distance(wc.φλ₀::geography, o.geom::geography)::numeric, 1) "От фотографа до ОСМ точки",
       'https://openstreetmap.org/'|| osm_type || '/' || osm_id "OSM URL",
       wc."URL" "ВикиСклад URL",
       wp."Адрес",
       o.geom "φλ OSM",
       wc.φλ₁,
       wc.φλ₀
  from "Бирюлёвский дендропарк: OSM"."Флористические таблички" o
  full outer join "Бирюлёвский дендропарк: ВикиСклад"."Флористические таблички" wc
    on wc.title = o.tags ->> 'wikimedia_commons'
  full outer join "Бирюлёвский дендропарк: Википедия"."Флористические таблички" wp
    on wp."Файл" = o.tags ->> 'wikimedia_commons'
 where not (o.osm_id is not null and wc.pageid is not null and (wp."Адрес" is not null or wp."Указание на аллею" is not null));

-- конец