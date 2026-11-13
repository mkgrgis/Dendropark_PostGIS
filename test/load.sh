echo '____________________
PastVu';
cat 'SQL/PastVu/Старые фото.sql' | psql || exit 10;

echo '____________________
Wikidata';
cat 'SQL/ВикиДанные/Wikidata.sql' | psql || exit 10;

echo '____________________
Wikipedia';
cat 'SQL/Википедия/Флора + таблички + ЦВР.sql' | psql || exit 10;

echo '____________________
Wikicommons';
cat 'SQL/ВикиСклад/Фото.sql' | psql || exit 10;

echo '____________________
Дмитрий';
cat 'SQL/Дмитрий/0_ODF.sql' | psql || exit 10;
cat 'SQL/Дмитрий/1_Данные.sql' | psql || exit 10;

echo '____________________
Обновление';
#cat 'SQL/Полное обновление.sql' | psql || exit 10;

echo '____________________
Валидаторы';
cat 'SQL/Валидаторы/0.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Адреса маточных площадок.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Водоёмы.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Дорожно-тропиночная сеть.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Классические аллеи.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Состав посадок маточных и коллекционных площадок.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Участки или кварталы.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Флористические таблички.sql' | psql || exit 10;
cat 'SQL/Валидаторы/Ценные видовые раскрытия.sql' | psql || exit 10;
