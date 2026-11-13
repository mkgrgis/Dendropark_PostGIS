echo '____________________
OSM';
apiadr='https://overpass-api.de/api/interpreter?data=';
#apiadr='https://overpass.openstreetmap.fr/api/interpreter?data=';
cat 'SQL/OSM/0_Основные.sql' | psql && './bash/OSM Дендропарк.sh' "$apiadr" && cat 'SQL/OSM/0_Основные.sql' | psql && cat 'SQL/OSM/1_Производные.sql' | psql && cat 'SQL/OSM/2_Маточные площадки.sql' | psql;
