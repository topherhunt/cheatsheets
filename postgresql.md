# PostgreSQL


## Basic navigation

- `\q` - exit
- `\?` - list all admin commands available
- `\h` - list all SQL commands available
- `\conninfo` - list info about current connection
- `\connect [database name]` - connect to a database


## Install & set up a specific version of Postgres (Ubuntu)

Generally, the _client_ version (eg. psql) needs to be >= the _server_ version.
Note that only certain versions are provided: -9.5, -9.6, -10, -11. See the link.

Steps:

  * Follow steps at: https://www.postgresql.org/download/linux/ubuntu/
  * `sudo apt-get install postgresql-9.6`
  * `sudo -u postgres psql -d postgres -c "CREATE ROLE ubuntu SUPERUSER CREATEDB LOGIN;"`
  * `createdb $(whoami)` (create a "home" db so you can use psql locally)
  * Now `psql` and `pg_dump` etc. should work as expected.

You can also remove most Postgres related packages like this:

    sudo apt-get remove postgresql-client-common


## Managing databases, users, roles

Create a default database for this user:

    createdb $(whoami)

Create a superadmin role:

    CREATE ROLE ubuntu SUPERUSER CREATEDB LOGIN;

Rename a database:

    ALTER DATABASE db RENAME TO newdb;


## Performance & scaling

  * Rule of thumb: Every FK should be indexed. This is important not only to keep join queries fast, but also to prevent gridlock when deleting rows in the associated table. If you try to delete rows in the FK target table, for each row it needs to scan the first table to ensure deleting the row won't violate any FKs. If this scan is unindexed, query time gets exponential fast. Fortunately, adding FKs after-the-fact isn't too painful (but test first!)


## Importing & exporting database structure & content

See also `ubuntu.md` which has some psql setup & remote connection tips.

Export the db schema to a file:

    pg_dump -c -s delphi_development > delphi-structure.sql

Export the content of selected tables:

    pg_dump delphi_development -c -t organizations -t users -t organizations_users -t schema_migrations > delphi-selected-tables.sql

Execute a .sql script:

    psql -d delphi_development -f delphi-structure.sql


## Importing & exporting SQL dumps

  - `pg_dump -h hostname -U username -d database_name --password > 2016-09-27-dumpfile.psql` (dump the entire database to a PSQL file that can be executed against another database to recreate the same state. Connection settings take same format as psql.)

  - You can also *export a SQL dump through SSH*, which eliminates the SCP step and is handy if the server has no free disk space: `ssh grayowl "pg_dump -h hostname -U username -d database_name --password" > 2016-09-27-dumpfile.psql` (will prompt for password as normal)

  - `psql -h localhost -U grayowlmaster --password grayowl_development < 2016-06-01_grayowl_staging.psql` (imports / executes a sql dump against a specified environment)


## Connecting to a remote database

URL connection format:

    psql username:password@hostname.us-east-1.rds.amazonaws.com:5432/database_name

NOTE: If your client is on postgres v9.6+, you MUST specify the port in the url when making remote connections. It may default to port 5434.


## Full-text search

- https://youtu.be/YWj8ws6jc0g?t=23m30s
- https://www.postgresql.org/docs/current/static/textsearch.html


## Regex substitution

- Advanced regex replacement in Postgres:
  `regexp_replace(url, 'https?://([^\/]+\.)*([\w\d\-\_]+\.[\w]+).*', '\2')`
- You can also use `substring(url from 'expression')` but it's less powerful I think.

This query gets the top-level domain from a URL string and uses it to count how many URLs are present for each domain.

```
SELECT
	DATE(found_at),
	regexp_replace(url, 'https?://([^\/]+\.)*([\w\d\-\_]+\.[\w]+).*', '\2') AS domain,
	COUNT(id) AS num_found
FROM candidates
WHERE found_at > '2016-09-15'
GROUP BY DATE(found_at), regexp_replace(url, 'https?://([^\/]+\.)*([\w\d\-\_]+\.[\w]+).*', '\2')
LIMIT 100;
```


## Disk space usage

- `pg_size_pretty(value)` - formats a number as KB, MB, GB etc.
- The following query returns disk usage info on the current db:

```
SELECT *
FROM (
  SELECT *, total_bytes - index_bytes - COALESCE(toast_bytes,0) AS table_bytes
  FROM (
    SELECT c.oid, nspname AS table_schema, relname AS TABLE_NAME,
      c.reltuples AS row_estimate,
      pg_total_relation_size(c.oid) AS total_bytes,
      pg_indexes_size(c.oid) AS index_bytes,
      pg_total_relation_size(reltoastrelid) AS toast_bytes
    FROM pg_class c
    LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE relkind = 'r'
  ) a
) a
ORDER BY table_schema, table_name;
```


## Install Postgres 9.5 on Ubuntu 16.04

(useful on DO & AWS instances which have the older version)

```
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo -u postgres psql -d postgres -c "CREATE ROLE ubuntu SUPERUSER CREATEDB LOGIN;"
createdb

# Now you can run `psql` to connect to your local db as superuser.
```
