cc -o "$(dirname "$0")/pghtmltable" \
	"$(dirname "$0")/pghtmltable.c" -lpq -I/usr/include/postgresql
# Пример использования
# PGCONN="host=localhost dbname='...' user='...' password='...'" ./pghtmltable 'select "№ п/п", "Уч.", "№₀", "№", "№ пОКН", "Адрес", "Адрес в ОКН", "объектов OSM", "URL" from "Бирюлёвский дендропарк: OSM"."№№ пл. по ОСМ";' > ./OSM.html
