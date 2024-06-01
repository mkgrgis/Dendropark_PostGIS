#!/bin/bash
# Обновление данных в PostGIS
[ ! -f 'postgres.url' ] && echo "✘ postgres.url" && exit;
pgurl=$(cat 'postgres.url');
r=$(echo "select '+';" | psql -A -t -q "$pgurl");
[ "$r" != "+" ] && echo "$r" && echo "✘ PostgreSQL URL ??? $pgurl" && exit;

lat_min=$(echo "$1" | cut -d ',' -f 1);
lon_min=$(echo "$1" | cut -d ',' -f 2);
lat_max=$(echo "$1" | cut -d ',' -f 3);
lon_max=$(echo "$1" | cut -d ',' -f 4);
# echo "$lon_min - $lon_max"
# echo "$lat_min - $lat_max"

apibase="https://pastvu.com/api2";
poly="{\"type\":\"Polygon\",\"coordinates\":[[[$lon_min,$lat_min],[$lon_max,$lat_min],[$lon_max,$lat_max],[$lon_min,$lat_max],[$lon_min,$lat_min]]]}";
paint1='false';
paint2='true';
apiadr1="$apibase?method=photo.getByBounds&params={\"z\":18,\"localWork\":true,\"isPainting\":$paint1,\"geometry\":$poly}";
apiadr2="$apibase?method=photo.getByBounds&params={\"z\":18,\"localWork\":true,\"isPainting\":$paint2,\"geometry\":$poly}";
s=$(date '+%s');
f1="$2 PastVu f $s.json";
f2="$2 PastVu i $s.json";
wget "$apiadr1" -O "$f1";
wget "$apiadr2" -O "$f2";
json1=$(cat "$f1" | sed "s/'/''/g");
json2=$(cat "$f2" | sed "s/'/''/g");
if [ "$json1" != "[]" ] && [ "$json2" != "[]" ]; then
	echo "truncate table \"$2\".\"∀ PastVu\";" | psql -e "$pgurl";
	echo "insert into \"$2\".\"∀ PastVu\" (\"r\", \"isPainting\") values ('$json1', $paint1);" | psql "$pgurl";
	r1=$?;
	echo "insert into \"$2\".\"∀ PastVu\" (\"r\", \"isPainting\") values ('$json2', $paint2);" | psql "$pgurl";
	r2=$?;
	echo " refresh materialized view \"$2\".\"PastVu ∀\";" | psql -e "$pgurl";
	if [ $r1 == 0 ] && [ $r2 == 0 ]; then
		echo "✔ PostGIS";
	    xz -z -9 "$f1";
  	    xz -z -9 "$f2";    
		#    rm -v "$f1";
		#    rm -v "$f2";	
	else
		echo "✘ PostGIS"; 
	fi;
else
	echo "✘ PastVu API json";
fi;
