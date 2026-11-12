#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"
#include "utils/memutils.h"
#include "varatt.h"
#include <zip.h>

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(unzip_bytea);

Datum
unzip_bytea(PG_FUNCTION_ARGS)
{
	bytea *zip_data;
	text *filename_text;
	char *filename;
	
	zip_error_t ziperror;
	zip_source_t *src;
	zip_t *za;
	zip_stat_t st;
	zip_file_t *zf;
	
	bytea *result;
	zip_int64_t bytes_read;

	/* Handle NULL inputs safely (though STRICT in SQL also handles this) */
	if (PG_ARGISNULL(0) || PG_ARGISNULL(1))
		PG_RETURN_NULL();

	/* Detoast input arguments to ensure contiguous memory */
	zip_data = PG_GETARG_BYTEA_PP(0);
	filename_text = PG_GETARG_TEXT_PP(1);
	filename = text_to_cstring(filename_text);

	zip_error_init(&ziperror);

	/* Create a libzip source directly from the bytea payload in memory */
	src = zip_source_buffer_create(
		VARDATA_ANY(zip_data),
		VARSIZE_ANY_EXHDR(zip_data),
		0, /* freep = 0: PostgreSQL palloc/detoast manages this memory */
		&ziperror
	);

	if (src == NULL)
	{
		ereport(ERROR,
				(errcode(ERRCODE_EXTERNAL_ROUTINE_EXCEPTION),
				 errmsg("failed to create zip source buffer: %s", zip_error_strerror(&ziperror))));
	}

	/* Open the zip archive from the memory source */
	za = zip_open_from_source(src, ZIP_RDONLY, &ziperror);
	if (za == NULL)
	{
		zip_source_free(src);
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("failed to open zip archive: %s", zip_error_strerror(&ziperror))));
	}

	/* Locate the file inside the archive and get its uncompressed size */
	zip_stat_init(&st);
	if (zip_stat(za, filename, 0, &st) != 0)
	{
		zip_close(za);
		zip_error_fini(&ziperror);
		pfree(filename);
		/* Return NULL if the requested file path does not exist in the archive */
		PG_RETURN_NULL();
	}

	/* Ensure the uncompressed size is valid and fits within PostgreSQL's 1GB varlena limit */
	if (!(st.valid & ZIP_STAT_SIZE))
	{
		zip_close(za);
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("could not determine uncompressed size for \"%s\"", filename)));
	}

	if (st.size > MaxAllocSize - VARHDRSZ)
	{
		zip_close(za);
		ereport(ERROR,
				(errcode(ERRCODE_PROGRAM_LIMIT_EXCEEDED),
				 errmsg("uncompressed file \"%s\" exceeds PostgreSQL 1GB limit", filename)));
	}

	/* Open the specific file inside the archive */
	zf = zip_fopen(za, filename, 0);
	if (zf == NULL)
	{
		const char *err_str = zip_strerror(za);
		zip_close(za);
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("failed to open file \"%s\" in archive: %s", filename, err_str)));
	}

	/* Allocate PostgreSQL bytea for the uncompressed output */
	result = (bytea *) palloc(st.size + VARHDRSZ);
	SET_VARSIZE(result, st.size + VARHDRSZ);

	/* Read the uncompressed bytes into the result buffer */
	bytes_read = zip_fread(zf, VARDATA(result), st.size);
	if (bytes_read < 0 || (zip_uint64_t) bytes_read != st.size)
	{
		zip_fclose(zf);
		zip_close(za);
		ereport(ERROR,
				(errcode(ERRCODE_DATA_EXCEPTION),
				 errmsg("failed to read complete file \"%s\" from archive", filename)));
	}

	/* Clean up libzip resources */
	zip_fclose(zf);
	zip_close(za); /* Also frees 'src' automatically upon success */
	zip_error_fini(&ziperror);
	pfree(filename);

	PG_RETURN_BYTEA_P(result);
}

