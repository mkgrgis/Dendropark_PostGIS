#!/bin/bash
# Снятие данных по дорожно-тропиночной сети
cd '/home/michail/GIS/Osm/Павловский парк ДТС'; echo 'SELECT "GeoJSON", "Название", "l" FROM "Павловский парк"."ДТС"' | psql -A -q -t -d "Геоинформационная система" | while read g; do
  gJ=$(echo "$g"|cut -f 1 -d '|');
  n=$(echo "$g"|cut -f 2 -d '|');
  l=$(echo "$g"|cut -f 3 -d '|'|tr '.' ',');
  echo "$gJ">"$n $l.geoJSON";
done;
