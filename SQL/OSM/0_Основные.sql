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
WHERE ("oпп".tags ->> 'leisure'::text) = 'park'::text AND ("oпп".tags ->> 'name'::text) = 'Бирюлёвский дендропарк: OSM'::text;

COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."Основная граница" IS 'Фильтр, выделяющий из данных, содержащих Бирюлёвский дендропарк: OSM его границу.';


CREATE MATERIALIZED VIEW "Бирюлёвский дендропарк: OSM"."∀"
TABLESPACE pg_default
AS SELECT "oпп".osm_id,
	"oпп".osm_type,
	"oпп".tags,
	st_intersection("ог".geom, "oпп".geom) AS geom,
	st_geometrytype(st_intersection("ог".geom, "oпп".geom)) geom_type
	FROM "Бирюлёвский дендропарк: OSM"."∀ osmium" "oпп"
	JOIN "Бирюлёвский дендропарк: OSM"."Основная граница" "ог" ON st_intersects("ог".geom, "oпп".geom)
WITH DATA;

COMMENT ON MATERIALIZED VIEW "Бирюлёвский дендропарк: OSM"."∀" IS 'Все данные, относящиеся к Бирюлёвскому дендропарку включая данные на его границах.';

CREATE OR REPLACE VIEW "Бирюлёвский дендропарк: OSM"."Участки"
AS SELECT osm_id,
		osm_type,
		(tags ->> 'name'::text)::smallint AS "№",
		tags ->> 'description'::text AS "Описание",
		geom
   FROM "Бирюлёвский дендропарк: OSM"."∀" a
  WHERE (tags ->> 'boundary'::text) = 'forest_compartment'::text AND (tags ->> 'name'::text) ~ '^\d+(\.\d+)?$'::text
  ORDER BY ((tags ->> 'name'::text)::smallint);
COMMENT ON VIEW "Бирюлёвский дендропарк: OSM"."Участки" IS 'Участки дендропарка по лесотехнической БД. Общая граница исключена из выборки.';

-- Убедиться что данные заполнились!
select ST_Area(ST_Transform(geom, 26986)) / 10000.0 "Площадь в га"
from "Бирюлёвский дендропарк: OSM"."Основная граница";
