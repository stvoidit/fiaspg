PGDATABASE=fias
PGHOST=localhost
PGPORT=5534
PGUSER=postgres
PGPASSWORD=postgres


ddl:
	PGDATABASE=$(PGDATABASE) PGHOST=$(PGHOST) PGPORT=$(PGPORT) PGUSER=$(PGUSER) PGPASSWORD=$(PGPASSWORD) \
	pg_dump -x --no-comments --format=plain --schema-only --no-owner > fias.sql

dump:
	PGDATABASE=$(PGDATABASE) PGHOST=$(PGHOST) PGPORT=$(PGPORT) PGUSER=$(PGUSER) PGPASSWORD=$(PGPASSWORD) \
	pg_dump --clean --if-exists --create -w --compress=0 -F custom -f fias.dump

restore:
	PGHOST=$(PGHOST) PGPORT=$(PGPORT) PGUSER=$(PGUSER) PGPASSWORD=$(PGPASSWORD) \
	pg_restore --dbname=$(PGDATABASE) --format=custom -x --clean --if-exists --exit-on-error --single-transaction --verbose fias.dump