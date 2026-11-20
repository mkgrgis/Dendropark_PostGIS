#!/bin/bash

# $1 - bbox области скачки, формат OSM Overpass API
# $2 - название схемы, хранящей загруженные данные
# $3 - название основного материализованого представления, хранящего фильтрованные данные
# $4 - URL точки OSM Overpass API

# Обновление данных в PostGIS по блоку скачиваемых данных
[ ! -f 'postgres.url' ] && echo "✘ postgres.url" && exit;
pgurl=$(cat 'postgres.url');
r=$(echo "select '+';" | psql -A -t -q "$pgurl");
[ "$r" != "+" ] && echo "$r" && echo "✘ PostgreSQL URL ??? $pgurl" && exit 100;

[ -z "$2" ] && exit 100; # Без схемы не работаем

bbox="$1";
s=$(date '+%s');
f="$2 $s";

if [ -z "$4" ]; then # Без точки доступа к OSM OverpassAPI пробуем закачку с адреса основного загрузчика
  wget "https://www.openstreetmap.org/api/0.6/map?bbox=$bbox" -O "$f.osm";
else
  wget "$4[out:xml];(++node($bbox);<;);(._;>;);out+meta;" -O "$f.osm";
fi
if [ ! -s "$f.osm" ]; then
  echo " OSM Overpass - 0 xml";
  rm "$f.osm";
  exit 10;
else
  osmium export --no-progress --config="$(dirname "$0")/osmium.conf" -f pg "$f.osm" -o "$f.pg" && echo "osmium ✔";
  echo -n "PostGIS geom: "$(wc -l "$f.pg")" ";
  echo "truncate table \"$2\".\"∀ osmium\";" | psql -e "$pgurl";
  echo "\\copy \"$2\".\"∀ osmium\" FROM '$f.pg';" | psql -e "$pgurl";
  r=$?;
  echo " refresh materialized view \"$2\".\"$3\";" | psql -e "$pgurl";
  if [ $r == 0 ]; then
    echo "✔ PostGIS";
    xz -z -9 "$f.osm";
    [ -f "$f.osm" ] && rm -v "$f.osm";
    rm -v "$f.pg";
    echo "osm.xz ✔";
  fi;
fi;
