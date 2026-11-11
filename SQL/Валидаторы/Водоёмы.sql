create view "Бирюлёвский дендропарк"."Водоёмы сводка" as
with wo as (
select ST_Union(geom) geom,
       sum(площадь) площадь,
       название,
       "название доп",
       "WikidataQ",
       "Построено",
       тип,
       "тип водотока"
  from "Бирюлёвский дендропарк: OSM"."Водоёмы" o   
  group by название, "название доп", "WikidataQ", "Построено", тип, "тип водотока"
  )
  select wo.*, wd.*
    from wo
    full join "Бирюлёвский дендропарк: WikiData"."Водоёмы" wd
      on wo."WikidataQ" = wd."Объект Q" 