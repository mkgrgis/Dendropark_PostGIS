#!/bin/bash
cd "$1";
htt="$(dirname "$0")/pghtmltable/pghtmltable.sh";
cp "$(dirname "$0")/pghtmltable/html/"* . -v;

ht='Cводка_маточных_площадок.html'; rm "$ht" -v;  PGPASSWORD=111111 "$htt" 'select * from "Бирюлёвский дендропарк"."№№ пл. сводка №№";' "$ht";

ht='Cводка_участков.html'; rm -v "$ht"; PGPASSWORD="111111" "$htt" 'select * from "Бирюлёвский дендропарк"."Участки сводка №№";' "$ht";

ht='Cводка_аллей.html'; rm -v "$ht"; PGPASSWORD="111111" "$htt" 'select * from "Бирюлёвский дендропарк"."Кл. аллеи сводка";' "$ht";
ht='Названия_аллей.html'; rm -v "$ht"; PGPASSWORD="111111" "$htt" 'select * from "Бирюлёвский дендропарк"."Кл. аллеи названия";' "$ht";
ht='Длины_аллей.html'; rm -v "$ht"; PGPASSWORD="111111" "$htt" 'select * from "Бирюлёвский дендропарк"."Кл. аллеи длины";' "$ht";
ht='Прочее_аллей.html'; rm -v "$ht"; PGPASSWORD="111111" "$htt" 'select * from "Бирюлёвский дендропарк"."Кл. аллеи другое";' "$ht";

python3 -m http.server;
