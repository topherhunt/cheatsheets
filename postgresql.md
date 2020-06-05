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

  * Rule of thumb: Every FK should be indexed. This is important not only to keep join queries fast, but also to prevent gridlock when deleting rows in the target table.

  * As table size grows beyond 1M records, `COUNT(*)` grows intolerably slow. If you need an exact count, there's no avoiding a full-table scan which is inefficient. But you can get an _estimated_ (within 0.1%) count quickly by querying the stats table:

    ```sql
    SELECT n_live_tup FROM pg_stat_all_tables WHERE relname = 'athletes';
    ```

  * Referential integrity (ie. FKs) means some amount of performance hit. But if you index properly, the hit will be small, and it's vastly preferable to risking total loss of data consistency.

  * Once you get into the "10M+ rows per table" scale, you need to plan more carefully and a lot of tough judgment calls come up. At this scale, stored procedures become extremely valuable, they let you do updates / deletions in smaller, more manageable steps to reduce the risk of causing performance problems.

  * A query / write taking 300ms is "a total disaster". A row deletion should take on the order of 1ms.

  * Useful discussion of SQL performance: https://dba.stackexchange.com/a/44345/32795


## Troubleshoot a slow query

  * First try EXPLAIN <query>.

  * That only gives cost estimates. See the actual costs by running EXPLAIN ANALYZE <query>.

  * If that still doesn't give enough info to help you diagnose the problem, try `ANALYZE VERBOSE tablename` to check the ratio btw live and dead rows.


## Importing & exporting database structure & content

See also `ubuntu.md` which has some psql setup & remote connection tips.

Export the db schema to a file:

    pg_dump -c -s delphi_development > delphi-structure.sql

Export the content of selected tables:

    pg_dump delphi_development -c -t organizations -t users -t organizations_users -t schema_migrations > delphi-selected-tables.sql

Execute a .sql script:

    psql -d delphi_development -f delphi-structure.sql

Copy a table to another table:

    CREATE TABLE c_trifecta_totals_bak AS TABLE c_trifecta_totals;


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

```sql
SELECT
	DATE(found_at),
	regexp_replace(url, 'https?://([^\/]+\.)*([\w\d\-\_]+\.[\w]+).*', '\2') AS domain,
	COUNT(id) AS num_found
FROM candidates
WHERE found_at > '2016-09-15'
GROUP BY DATE(found_at), regexp_replace(url, 'https?://([^\/]+\.)*([\w\d\-\_]+\.[\w]+).*', '\2')
LIMIT 100;
```


## Dates & times

  * Display a timestamp as a date: `DATE(found_at)`
  * Display a date's year as string: `DATE_PART('year', a.created_at)`
  * Add 1 month to a timestamp: `NOW() + INTERVAL '1 month'`


## Updates using a join table

```sql
-- An example of updating one table based on associated data in another table (or more):
UPDATE cevents
SET series_id = events.series_id
FROM events
WHERE cevents.identifier = events.identifier
  AND events.series_id IS NOT NULL
  AND cevents.series_id IS NULL
  AND cevents.chronotrack_event_id IN (SELECT ct_id FROM tmp_chrono_ids_and_series_names);
```


## Temporary tables

Useful for joining on non-persisted lists of data etc.

```sql
CREATE TEMP TABLE chrono_ids (id integer PRIMARY KEY);
INSERT INTO chrono_ids (id) VALUES (1), (2), (3), (100), (101), (103), (106), (107), (108), (109), (111), (112), (114), (115), (116), (117), (123), (124), (125), (126), (127), (130), (131), (132), (133), (134), (135), (136), (137);
-- Now you can join to this temp table just like any other
SELECT * FROM some_other_table t WHERE t.chronotrack_id IN (chrono_ids);
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
      pg_total_relation_size(c.oid) / 1000000 AS total_mb,
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


## Update many rows with different values

You can batch-update many rows in a table, each with its own value, in a single query, using this pattern. Useful when updating thousands of rows with different values:

```sql
UPDATE entries e
SET rank = t.rank
FROM (VALUES
  (1234, 1), (1346, 2), (2863, 3), (5827, 4), (5132, 5), (1245, 6), ...
) AS t(entry_id, rank)
WHERE e.id = t.entry_id
```


## Viewing connected processes & running queries

```sql
-- Show details of each currently running query
SELECT xact_start, query_start, query FROM pg_stat_activity WHERE state != 'idle';
```


## Full-text search in Postgres

Below is a demo script for a basic PG full-text search system using a dedicated table (searchables) as the search index.

See also:
  - https://www.postgresql.org/docs/11/textsearch-intro.html
  - https://www.postgresql.org/docs/11/textsearch-controls.html#TEXTSEARCH-RANKING
  - https://thoughtbot.com/blog/optimizing-full-text-search-with-postgres-tsvector-columns-and-triggers
  - http://rachbelaid.com/postgres-full-text-search-is-good-enough/

```sql
DROP TABLE searchables;

-- We'll create a dedicated `searchables` table to use as our search index.
-- To make search fast, we'll store the tsvector (parsed lexemes), and index them.
CREATE TABLE searchables (
  id SERIAL PRIMARY KEY,
  text_a TEXT,
  text_b TEXT,
  tsvector TSVECTOR);
CREATE INDEX searchables_tsv_idx ON searchables USING GIN (tsvector);

-- Populate some example values.
INSERT INTO searchables (text_a, text_b) VALUES
('Topher Hunt', 'a programmer who enjoys biking and video games. He''s Lily Truong''s husband.'),
('Lily Truong', 'a businesswoman who lives in the Netherlands and does not enjoy biking. Topher Hunt''s wife.'),
('Don Hunt', 'Topher Hunt''s father, who is suffering from FTD. ');

-- Now populate the tsvector field from the "raw" source fields (and apply weightings).
UPDATE searchables
SET "tsvector" = setweight(to_tsvector(COALESCE(text_a, '')), 'A') || setweight(to_tsvector(COALESCE(text_b, '')), 'B')
WHERE "tsvector" IS NULL;

-- Inspect the full contents of the searchables table
SELECT * FROM searchables;

-- A full-text search against the searchables table (with field weightings so we can rank later on)
SELECT id, text_a, text_b, ts_rank(tsvector, query) AS rank
FROM searchables, websearch_to_tsquery('hunt') AS query
WHERE tsvector @@ query
ORDER BY rank DESC;

-- websearch_to_tsquery can also accept basic search syntax like OR, -, and quotes.
SELECT websearch_to_tsquery('linux OR "world domination" -trump');
```
