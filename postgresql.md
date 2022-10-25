# PostgreSQL


## Resources

  - https://github.com/LendingHome/zero_downtime_migrations - Rails gem with helpful tips on how to do non-locking migrations on high-traffic tables.


## Process startup

If Postgres is crashing on OSX, try these commands:

  - `brew services list`
  - `brew services restart postgresql`
  - `brew info postgres`
  - `tail -f /var/log/system.log`
  - `pg_ctl -D /usr/local/var/postgres start` # run this and check the error output
  - Try `brew remove postgresql` then `brew install postgresql` (fresh reinstall)


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

  * Pagination using LIMIT & OFFSET is very expensive. Consider using a "deferred join" to make it more efficient: https://aaronfrancis.com/2022/efficient-pagination-using-deferred-joins and https://planetscale.com/blog/fastpage-faster-offset-pagination-for-rails-apps - but also see more discussion & concerns about: https://news.ycombinator.com/item?id=29969099, https://twitter.com/mdavis1982/status/1482429071288066054, https://news.ycombinator.com/item?id=32484807

  * Rule of thumb: Every FK should be indexed. This is important not only to keep join queries fast, but also to prevent gridlock when deleting rows in the target table.

  * As table size grows beyond 1M records, `COUNT(*)` grows intolerably slow. If you need an exact count, there's no avoiding a full-table scan which is inefficient. But you can get an _estimated_ (within 0.1%) count quickly by querying the stats table:

    ```sql
    SELECT n_live_tup FROM pg_stat_all_tables WHERE relname = 'athletes';
    ```

  * Referential integrity (ie. FKs) means some amount of performance hit. But if you index properly, the hit will be small, and it's vastly preferable to risking total loss of data consistency.

  * Once you get into the "10M+ rows per table" scale, you need to plan more carefully and a lot of tough judgment calls come up. At this scale, stored procedures become extremely valuable, they let you do updates / deletions in smaller, more manageable steps to reduce the risk of causing performance problems.

  * A query / write taking 300ms is "a total disaster". A row deletion should take on the order of 1ms.

  * Useful discussion of SQL performance: https://dba.stackexchange.com/a/44345/32795


## Misc. query tips

  * Check if 1 array contains any item in another array (test for array intersection):
    `SELECT * FROM redeemed_trifectas WHERE event_ids && ARRAY[7096, 7097, 7098, 7099];`


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


## Random numbers

  * `SELECT RANDOM();` => decimal between 0 and 1
  * `FLOOR(RANDOM() * 900 + 100);` => integer between 100 and 999

Select a random subset of rows from another query:

```sql
-- Select a random 10% of the 100K most recently active users
SELECT *
FROM (SELECT id FROM users ORDER BY last_logged_in_at DESC LIMIT 100000) t
WHERE RANDOM() > 0.1;
```


## Dates & times

  * Convert a timestamp to a date: `DATE(created_at)` or `created_at::date`
  * Convert a date to a timestamp (beginning of day): `date::timestamp`
  * Display a date's year as string: `DATE_PART('year', a.created_at)`
  * Format a date/time to a time string: `TO_CHAR(a.created_at, 'HH24:MI')`
    (see https://www.postgresql.org/docs/13/functions-formatting.html for more detail)
  * Add 1 month to a timestamp: `NOW() + INTERVAL '1 month'`


## Insertions

Insert hard-coded rows into a table:

```sql
INSERT INTO teams (name, description)
VALUES ('Team 1', 'blah blah blah'),
       ('Team 2', 'blah blah blah'),
       ...
```

Insert rows based on output of a SELECT statement:

```sql
INSERT INTO teams (name, description)
SELECT name, description FROM teams_old LIMIT 100;
```


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


## Nested queries

Here's a simple nested query:

```sql
-- List a random 5% subset of unique athlete IDs from the ~10K highest-performing athletes:
SELECT athlete_user_id FROM (
  SELECT athlete_user_id FROM (
    SELECT athlete_user_id FROM trifecta_totals ORDER BY num_trifectas DESC LIMIT 10000
  ) t GROUP BY athlete_user_id
) t
WHERE RANDOM() < 0.05;
```


## Temporary tables

Useful for joining on non-persisted lists of data etc.

```sql
CREATE TEMP TABLE chrono_ids (id integer PRIMARY KEY);
INSERT INTO chrono_ids (id) VALUES (1), (2), (3), (100), (101), (103), (106), (107), (108), (109), (111), (112), (114), (115), (116), (117), (123), (124), (125), (126), (127), (130), (131), (132), (133), (134), (135), (136), (137);
-- Now you can join to this temp table just like any other
SELECT * FROM some_other_table t WHERE t.chronotrack_id IN (chrono_ids);
```


## CSV export & import

You can specify what fields to export (default = all), the file path, delimiter, and whether to include a header.

```sql
COPY athlete_users(id, email, first_name, last_name, gender, created_at, updated_at)
TO '/Users/topher/Downloads/athlinks-bak/athlete_users.csv' DELIMITER ',' CSV HEADER;
```

You can import data from .csv in a similar way:

```sql
COPY athlete_users(id, email, first_name, last_name, gender, created_at, updated_at)
FROM '/Users/topher/Downloads/athlinks-bak/athlete_users.csv' DELIMITER ',' CSV HEADER
```


## Disk space usage

- `pg_size_pretty(value)` - formats a number as KB, MB, GB etc.

```sql
-- List all tables with disk usage info
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


## Sequences

Sometimes, eg. in a staging DB, primary key sequences can get out of sync with the max id in the table.

List all sequences in this DB:

```sql
SELECT relname sequence_name FROM pg_class WHERE relkind = 'S';
```

Reset a sequence to the max id:

```sql
SELECT MAX(id) FROM teams; -- => 18687
ALTER SEQUENCE teams_id_seq RESTART WITH 18688;
```



## Viewing connections / processes / running queries

```sql
-- Show details of each currently running query
SELECT xact_start, query_start, query FROM pg_stat_activity WHERE state != 'idle';
```


## Full-text search

Below is a demo script for a basic PG full-text search system using a dedicated table (searchables) as the search index.

See also:

  - https://www.postgresql.org/docs/11/textsearch-intro.html
  - https://www.postgresql.org/docs/11/textsearch-controls.html#TEXTSEARCH-RANKING
  - https://thoughtbot.com/blog/optimizing-full-text-search-with-postgres-tsvector-columns-and-triggers
  - http://rachbelaid.com/postgres-full-text-search-is-good-enough/
  - https://youtu.be/YWj8ws6jc0g?t=23m30s
  - https://www.postgresql.org/docs/current/static/textsearch.html


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

### Full-text search, using Postgres triggers

Below is an example of setting up a full-text search field whose contents are maintained at the DB layer via a trigger and function, so you don't need to remember to refresh their contents via app code:

```rb
  def up
    execute <<-SQL
      ALTER TABLE athlete_users ADD COLUMN searchable tsvector;

      CREATE FUNCTION update_athlete_users_searchable_trigger() RETURNS trigger AS $$
      begin
        new.searchable :=
          setweight(to_tsvector('english', coalesce(new.email, '')), 'A') ||
          setweight(to_tsvector('english', coalesce(new.first_name,'')), 'B') ||
          setweight(to_tsvector('english', coalesce(new.last_name,'')), 'C');
        return new;
      end
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER update_athlete_users_searchable BEFORE INSERT OR UPDATE OF email, first_name, last_name
          ON athlete_users FOR EACH ROW EXECUTE PROCEDURE update_athlete_users_searchable_trigger();
    SQL
  end
```



### Autocomputed sequential ranks using `ROW_NUMBER()`

https://www.postgresqltutorial.com/postgresql-row_number/


### CREATE INDEX CONCURRENTLY

- Be warned, creating an index concurrently can take way longer (in extreme cases 200x longer) than creating the same index non-concurrently. https://dba.stackexchange.com/a/212514/32795
- Also be aware that while indexes created concurrently don't lock the table from being written, the Rails migration will "block" and wait until the index has been completely built. So watch out for deploy timeouts due to the Rails migration taking too long.
- Sometimes creating an index concurrently takes way longer than it should. If that happens, use these queries to check if the index is still building or has failed (and thus must be dropped & recreated): https://dba.stackexchange.com/a/242079/32795
- See also the official docs for caveats on concurrent indexes: https://www.postgresql.org/docs/9.3/sql-createindex.html#SQL-CREATEINDEX-CONCURRENTLY
