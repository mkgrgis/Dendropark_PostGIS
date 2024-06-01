#!/bin/bash
# Обновление данных в PostGIS
[ ! -f 'postgres.url' ] && echo "✘ postgres.url" && exit;
pgurl=$(cat 'postgres.url');
r=$(echo "select '+';" | psql -A -t -q "$pgurl");
[ "$r" != "+" ] && echo "✘ PostgreSQL URL ??? $pgurl" && exit;

apiadr="https://wikimap.toolforge.org/api.php";
apiadr="$apiadr?cat=$1&subcats&subcatdepth=8&camera=true&locator=true&allco=true";
echo "$apiadr";
s=$(date '+%s');
f="$2 WikiMap $s.json";
wget "$apiadr" -O "$f"
json=$(cat "$f" | sed "s/'/''/g");
if [ "$json" != "[]" ]; then
	echo "truncate table \"$2\".\"∀ WikiMap\";" | psql -e "$pgurl";
	echo "insert into \"$2\".\"∀ WikiMap\" (\"r\") values ('$json');" | psql "$pgurl";
	r=$?;
	echo " refresh materialized view \"$2\".\"WikiMap ∀\";" | psql -e "$pgurl";
	if [ $r == 0 ]; then
    	echo "✔ PostGIS";
    	xz -z -9 "$f";
    	#    rm -v "$f";
    else
    	echo "✘ PostGIS"; 
	fi;
	else
		echo "✘ WikiMap API json";
fi;
