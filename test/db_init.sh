echo "create user \"$2\" password '$3';" | sudo -u postgres psql;
echo "create database \"$1\" owner \"$2\";" | sudo -u postgres psql;

echo "CREATE EXTENSION postgis;
CREATE EXTENSION http;
CREATE EXTENSION file_fdw;

CREATE SERVER \"Wiki дендропарк\" FOREIGN DATA WRAPPER file_fdw;
grant usage on foreign server \"Wiki дендропарк\" to \"$2\";
grant pg_execute_server_program to \"$2\"; " | sudo -u postgres psql -d "$1";
