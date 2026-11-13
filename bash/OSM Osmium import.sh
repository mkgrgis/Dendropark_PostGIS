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
[ -z "$4" ] && exit 100; # Без точки доступа к OSM OverpassAPI не работаем

bbox="$1";
apiadr="$4";
apiadr="$apiadr[out:xml];(++node($bbox);<;);(._;>;);out+meta;";
echo "$apiadr";
s=$(date '+%s');
f="$2 $s";
#wget "$apiadr" -O - -o /dev/null > "$f.osm";
wget "$apiadr" -O "$f.osm";
if [ ! -s "$f.osm" ]; then
  echo " OSM Overpass - 0 xml";
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
