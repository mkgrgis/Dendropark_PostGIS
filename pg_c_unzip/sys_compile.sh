sudo apt install -y libzip-dev pkg-config;
sudo apt --fix-broken install;

sudo apt install -y postgresql-common;
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y;
sudo apt update;
sudo apt install postgresql-server-dev-18 postgresql-client-18;

(cd "$(dirname "$0")"; make pg_unzip.so; make; sudo make install; make clean;)
