EXTENSION = pg_unzip
DATA = pg_unzip--1.0.sql

MODULE_big = pg_unzip
OBJS = pg_c_unzip.o

PG_CPPFLAGS = $(shell pkg-config --cflags libzip)
SHLIB_LINK = $(shell pkg-config --libs libzip)

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)
