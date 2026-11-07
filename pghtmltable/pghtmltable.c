#include <stdio.h>
#include <stdlib.h>
#include <libpq-fe.h>
#include <string.h>
#include <18/server/catalog/pg_type_d.h>

extern char *ewkb_hex_to_geojson(const char *s);

static void html_escape(const char *s) {
	if (strncmp(s, "https", 5) == 0) {
		size_t len = strlen(s);
		char *out = malloc(len * 2 + 32);
		if (out)
			fprintf(stdout, "<a href=\"%s\">%s</a>", s, s);
	} 
	else
	for (; *s; s++) {
		switch (*s) {
			case '&':  fputs("&amp;", stdout); break;
			case '<':  fputs("&lt;", stdout);  break;
			case '>':  fputs("&gt;", stdout);  break;
			case '"':  fputs("&quot;", stdout); break;
			case '\'': fputs("&#39;", stdout); break;
			default:   putchar(*s); break;
		}
	}
}

static Oid get_geometry_oid(PGconn *conn) {
	PGresult *r = PQexec(conn, "SELECT 'geometry'::regtype::oid");
	Oid oid = InvalidOid;
	if (PQresultStatus(r) != PGRES_TUPLES_OK) {
		fprintf(stderr, "%s\n", PQerrorMessage(conn));
		PQclear(r);
		return InvalidOid;
	}
	oid = (Oid)strtoul(PQgetvalue(r, 0, 0), NULL, 10);
	PQclear(r);
	return oid;
}

static void print_result(PGconn *conn, PGresult *res) {
	int nfields, nrows, i, j ;
	int nmap = 0;
	int x2 = 1;
	Oid geom_oid = get_geometry_oid(conn);
	nfields = PQnfields(res);
	nrows = PQntuples(res);

	fprintf(stdout, "<table border=\"1\">\n");
	fprintf(stdout, "  <thead><tr>");
	for (i = 0; i < nfields; i++) {
		fprintf(stdout, "<th>");
		html_escape(PQfname(res, i));
		fprintf(stdout, "</th>");
	}
	fprintf(stdout, "</tr></thead>\n  <tbody>\n");

	for (i = 0; i < nrows; i++) {
		if (x2) {
			x2 = 0;
			fprintf(stdout, "	<tr class=\"odd\">");
			}
		else {
			fprintf(stdout, "	<tr>");
			x2 = 1;
		}
		for (j = 0; j < nfields; j++) {
			int bool_t = PQftype(res, j) == BOOLOID;
			if (PQgetisnull(res, i, j)) {
				fprintf(stdout, "<td>");
				fprintf(stdout, "␀");
			} else  if (PQftype(res, j) == geom_oid) { /* ST_AsGeoJSON(geom) ! */
				char *ewkbhex = PQgetvalue(res, i, j);
				//char *geojson = ewkb_hex_to_geojson(ewkb);
				fprintf(stdout, "<td><div class=\"objmap\" id=\"map%i\"></div>\n  <script>\n    ewkbMap('%s', 'map%i');\n   </script>", nmap, ewkbhex, nmap);
				nmap++;
			} else if (bool_t) {
				int bool_ok = PQgetvalue(res, i, j)[0] == 't';
				fprintf(stdout, "<td style=\"background-color: %s\">", bool_ok ? "#CAF3A3" : "#FA5050" );
				fprintf(stdout, "%s", bool_ok ? "✔" : "✘");
			} else {
				fprintf(stdout, "<td>");
				html_escape(PQgetvalue(res, i, j));
			}
			fprintf(stdout, "</td>");
		}
		fprintf(stdout, "</tr>\n");
	}

	fprintf(stdout, "  </tbody>\n</table>\n");
}

int main(int argc, char **argv) {
	// Соединение с БД
	const char* password = getenv("PGPASSWORD");
	const char* pghost = getenv("PGHOST");
	const char* pgport = getenv("PGPORT");
	const char* dbname = getenv("PGDATABASE");
	const char* pguser = getenv("PGUSER");
	const char* pgoptions = NULL;

	const char *query = NULL;
	PGconn *conn;
	PGresult *res;

	// Без запроса не имеет смысла
	if (argc < 2) {
		fprintf(stderr, "Usage: %s \"SQL query\"\nRetcodes: 1-no DB, 2-no good query, 3-SQL err", argv[0]);
		return 1;
	}
	query = argv[1];

	if (password == NULL) {
		fprintf(stderr,"Пароль в переменной окружения PGPASSWORD не задан! Будьте внимательны к ошибкам отказа в доступе\n");
	}
	
	conn = PQsetdbLogin(pghost, pgport, pgoptions, NULL, dbname, pguser, password);
	if (PQstatus(conn) != CONNECTION_OK) {
		fprintf(stderr, "Ошибка соединения с БД: %s\n", PQerrorMessage(conn));
		PQfinish(conn);
		return 1;
	}

	res = PQexec(conn, query);
	if (!res) {
		fprintf(stderr, "Query failed: %s", PQerrorMessage(conn));
		PQfinish(conn);
		return 2;
	}

	if (PQresultStatus(res) != PGRES_TUPLES_OK) {
		fprintf(stderr, "SQL error: %s", PQresultErrorMessage(res));
		PQclear(res);
		PQfinish(conn);
		return 3;
	}

	print_result(conn, res);

	PQclear(res);
	PQfinish(conn);
	return 0;
}
