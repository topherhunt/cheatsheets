# Ecto, schemas, Repo

  * Make a field virtual (not persisted): `virtual: true`
  * Define a field as a List by giving it type: `{:array, :string}`
  * Association on_delete callbacks are best defined at the db layer, but can also be defined on the schema association field. (less performant)


## Gotchas

  * In queries, never use `NOW()` with a `timestamp without time zone` field! This will compare using the DB's configured timezone, which might not be UTC. Instead, inject a timezone-bearing value like `DateTime.utc_now()`.

Changesets:

  * See `Ecto.Changeset` hexdocs for full list of available validation & constraints.

  *  Warning: If you misspell a field in a validation macro, *it will silently skip that field*. Ensure test coverage of all validations.

  * Warning: `*_constraint` functions simply catch db-layer constraint errors and convert them to friendly object validation error messages; if you haven't added the corresponding db-layer constraint, these functions will have no effect.

Migrations:

  * Never load schema records or use changesets within a migration. The schema and changesets assume that the table is in the latest state, but this often isn't true for old migrations. Instead, write your own Ecto queries to select specific fields for any data you need, and run execute statements to do inserts/updates/deletes.

Floats & decimals in Ecto:

  * Use Float when you can get away with it. Only use Decimal when you need absolute precision of values.

  * Elixir has no built-in support for decimals, you need to add the `Decimal` dep for that. Decimal has a somewhat verbose api since the standard arithmetic functions aren't compatible with this data type.

  * **Watch out:** If using Decimals, use `Decimal.cmp/2` to compare values. Never use kernel comparators like `>=`; this will use Erlang term comparison which doesn't work the way you'd expect it to.

  * See also: https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types

Run a raw query in your code, with sanitized values:

```ruby
Repo.query!("SELECT id FROM athletes WHERE id = $1", [athlete.id])
```

Run a raw query in your migration:

```ruby
execute "UPDATE users SET name = email WHERE name IS NULL;"
```

How to connect to a custom database URL (eg. in an exs script):
https://thepugautomatic.com/2020/06/connecting-ecto-to-a-legacy-database-in-a-script/
