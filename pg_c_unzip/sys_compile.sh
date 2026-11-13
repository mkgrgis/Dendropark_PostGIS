cd "$(dirname "$0")";
make pg_unzip.so;
make;
sudo make install;
make clean;
