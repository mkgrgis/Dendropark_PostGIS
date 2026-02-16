echo "create user \"$2\" password '$3';" | sudo -u postgres psql;
echo "create database \"$1\" owner \"$2\";" | sudo -u postgres psql;
