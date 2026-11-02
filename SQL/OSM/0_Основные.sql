-- Все объекты будут размещены в специальной схеме
CREATE SCHEMA "Бирюлёвский дендропарк: OSM";

CREATE TABLE "Бирюлёвский дендропарк: OSM"."∀ osmium" (
	geom geometry NULL,
	osm_type varchar(8) NULL,
	osm_id int8 NULL,
	"version" int4 NULL,
	changeset int4 NULL,
	uid int4 NULL,
	"user" varchar(256) NULL,
	"timestamp" timestamptz(0) NULL,
	way_nodes _int8 NULL,
	tags jsonb NULL
);
COMMENT ON TABLE "Бирюлёвский дендропарк: OSM"."∀ osmium" IS 'Таблица для Osmium импорта данных, покрывающих Бирюлёвский дендропарк: OSM. Данные впоследствии фильтруюется по границам парка.';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Основная граница"
AS SELECT "oпп".tags ->> 'name'::text AS "Название",
	"oпп".tags ->> 'operator'::text AS "Оператор",
	"oпп".osm_id,
	"oпп".geom
FROM "Бирюлёвский дендропарк: OSM"."∀ osmium" "oпп"
WHERE ("oпп".tags ->> 'leisure'::text) = 'park'::text AND ("oпп".tags ->> 'name'::text) = 'Бирюлёвский дендропарк'::text;

COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."Основная граница" IS 'Фильтр, выделяющий из данных, содержащих Бирюлёвский дендропарк: OSM его границу.';


CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк: OSM"."∀"
TABLESPACE pg_default
AS SELECT a.osm_id,
	a.osm_type,
	a.tags,
	st_intersection("ог".geom, a.geom) AS geom,
	st_geometrytype(st_intersection("ог".geom, a.geom)) geom_type,
	'https://openstreetmap.org/'|| a.osm_type || '/' || a.osm_id "OSM URL"
	FROM "Бирюлёвский дендропарк: OSM"."∀ osmium" a
	JOIN "Бирюлёвский дендропарк: OSM"."Основная граница" "ог" ON st_intersects("ог".geom, a.geom)
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Бирюлёвский дендропарк: OSM"."∀" IS 'Все данные, относящиеся к Бирюлёвскому дендропарку включая данные на его границах.';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Участки"
AS SELECT osm_id,
		osm_type,
		(tags ->> 'name'::text)::smallint AS "№",
		string_to_array(tags ->> 'old_ref', ';'::text) AS "Старые номера",
		tags ->> 'description'::text AS "Описание",
		geom,
		"OSM URL"
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (tags ->> 'boundary'::text) = 'forest_compartment'::text AND (tags ->> 'name'::text) ~ '^\d+(\.\d+)?$'::text
  ORDER BY ((tags ->> 'name'::text)::smallint);
COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."Участки" IS 'Участки дендропарка по лесотехнической БД. Общая граница исключена из выборки.';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Участки проекта 1941 г."
AS SELECT unnest("Старые номера")::smallint AS "№ 1941 г.",
    "№" AS "№ 1962 г.",
    osm_id,
    osm_type,
    "Описание",
    geom,
    "OSM URL"
   FROM "Бирюлёвский дендропарк: OSM"."Участки"
  ORDER BY (unnest("Старые номера")::smallint);
COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."Участки проекта 1941 г." IS 'Указатель участков по старой нумерации в соотношении М:М с участками новой нумерации. Обычно участки старой нумерации меньше.';

-- Прповерка полноты натурального ряда старых кодов участков по проекту 1941 года
select u.* from generate_series(1,89) n
full join "Бирюлёвский дендропарк: OSM"."Участки проекта 1941 г." u on u."№ 1941 г." = n.n

-- Убедиться что данные заполнились!
select ST_Area(ST_Transform(geom, 26986)) / 10000.0 "Площадь в га"
from "Бирюлёвский дендропарк: OSM"."Основная граница";
