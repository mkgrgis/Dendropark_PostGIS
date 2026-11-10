#!/bin/bash
cd "$(dirname "$0")";
rm pghtmltable/pghtmltable; # компилируемый файл
find . -type f -name *.sql -exec sed -i 's/[[:blank:]]\+$//' {} +;
git add . && git commit && git push;
./pghtmltable/compile.sh; # восстановим компилируемый
