CREATE OR REPLACE FUNCTION unzip_bytea(x bytea, n text)
RETURNS bytea
AS 'pg_unzip', 'unzip_bytea'
LANGUAGE C IMMUTABLE STRICT PARALLEL SAFE;
