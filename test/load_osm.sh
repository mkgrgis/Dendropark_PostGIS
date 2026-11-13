echo '____________________
OSM';
cat 'SQL/OSM/0_Основные.sql' | psql && './bash/OSM Дендропарк.sh' && cat 'SQL/OSM/0_Основные.sql' | psql && cat 'SQL/OSM/1_Производные.sql' | psql && cat 'SQL/OSM/2_Маточные площадки.sql' | psql;
