#include <stdio.h>
#include <stdlib.h>
#include <libpq-fe.h>
#include <string.h>
#include <18/server/catalog/pg_type_d.h>

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

int main(int argc, char **argv) {
	const char *conninfo = getenv("PGCONN");
	const char *query = NULL;
	PGconn *conn;
	PGresult *res;
	int nfields, nrows, i, j;
	int x2 = 1;

	if (!conninfo) conninfo = "dbname=postgres";
	if (argc < 2) {
		fprintf(stderr, "Usage: %s \"SQL query\"\n", argv[0]);
		return 1;
	}
	query = argv[1];

	conn = PQconnectdb(conninfo);
	if (PQstatus(conn) != CONNECTION_OK) {
		fprintf(stderr, "Connection failed: %s", PQerrorMessage(conn));
		PQfinish(conn);
		return 1;
	}

	res = PQexec(conn, query);
	if (!res) {
		fprintf(stderr, "Query failed: %s", PQerrorMessage(conn));
		PQfinish(conn);
		return 1;
	}

	if (PQresultStatus(res) != PGRES_TUPLES_OK) {
		fprintf(stderr, "SQL error: %s", PQresultErrorMessage(res));
		PQclear(res);
		PQfinish(conn);
		return 1;
	}

	nfields = PQnfields(res);
	nrows = PQntuples(res);

	printf("<table border=\"1\">\n");
	printf("  <thead><tr>");
	for (i = 0; i < nfields; i++) {
		printf("<th>");
		html_escape(PQfname(res, i));
		printf("</th>");
	}
	printf("</tr></thead>\n  <tbody>\n");

	for (i = 0; i < nrows; i++) {
		if (x2) {
			x2 = 0;
			printf("	<tr class=\"odd\">");
			}
		else {
			printf("	<tr>");
			x2 = 1;
		}
		for (j = 0; j < nfields; j++) {
			int bool_t = PQftype(res, j) == BOOLOID;
			if (PQgetisnull(res, i, j)) {
				printf("<td>");
				printf("␀");
			} else if (bool_t) {
				int bool_ok = PQgetvalue(res, i, j)[0] == 't';
				printf("<td style=\"background-color: %s\">", bool_ok ? "#CAF3A3" : "#FA5050" );
				printf("%s", bool_ok ? "✔" : "✘");
			} else {
				printf("<td>");
				html_escape(PQgetvalue(res, i, j));
			}
			printf("</td>");
		}
		printf("</tr>\n");
	}

	printf("  </tbody>\n</table>\n");

	PQclear(res);
	PQfinish(conn);
	return 0;
}
