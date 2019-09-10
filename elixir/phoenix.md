# Phoenix: Structure, components, tips


## Useful commands

  * `mix phx.new app_name`

  * `mix phx.server`

  * `mix phx.gen.html Accounts User users name:string email:string password_hash:string last_signed_in_at:utc_datetime` - generate a context, schema, and scaffold controller & templates


## Env

  * Standard envs are `dev`, `test`, and `prod`.

  * Check the current env: `Mix.env()`

  * Set the env for a command: `MIX_ENV=test mix ecto.reset`

  * Your deps always run in `prod` regardless of your main app's environment.


# Contexts

  * Rather than your controllers etc. having direct access to query & write persisted data using your schemas, Phoenix uses *context* modules as an internal boundary. All interactions between a schema and the outside world should happen only through its publicly-exposed context functions.

  * Example breakdown: A high-traffic production Phoenix app (for local event announcements & registrations) has ended up with the following 8 contexts: `auth`, `email`, `faq`, `newsletter`, `pdf`, `registration`, `ticketing`, and `support`. Together these contexts contain ~ 50 schemas total.


## Ecto, schemas, Repo

  * Make a field virtual (not persisted): `virtual: true`
  * Define a field as a List by giving it type: `{:array, :string}`
  * Association on_delete callbacks are best defined at the db layer, but can also be defined on the schema association field. (less performant)

Changesets:

  * See `Ecto.Changeset` hexdocs for full list of available validation & constraints.

  *  Warning: If you misspell a field in a validation macro, *it will silently skip that field*. Ensure test coverage of all validations.

  * Warning: `*_constraint` functions simply catch db-layer constraint errors and convert them to friendly object validation error messages; if you haven't added the corresponding db-layer constraint, these functions will have no effect.

Associations:

  * You must explicitly preload associations. No lazy loading like in Rails.

  * Preload an association at query time:
    `Ecto.Query.preload(query, :videos)`

  * Load an assoc (onto the parent struct) after query time:
    `Repo.preload(user, :videos)`

  * Load the associated data and return it as a list (not on the parent struct):
    `Ecto.assoc(user, :videos)`

  * Fetching nested associations is easy: `Ecto.assoc(post, [:comments, :author]`

Migrations:

  * Never load schema records or use changesets within a migration. The schema and changesets assume that the table is in the latest state, but this often isn't true for old migrations. Instead, write your own Ecto queries to select specific fields for any data you need, and run execute statements to do inserts/updates/deletes.

Floats & decimals in Ecto:

  * Use Float when you can get away with it. Only use Decimal when you need absolute precision of values.

  * Elixir has no built-in support for decimals, you need to add the `Decimal` dep for that. Decimal has a somewhat verbose api since the standard arithmetic functions aren't compatible with this data type.

  * **Watch out:** If using Decimals, use `Decimal.cmp/2` to compare values. Never use kernel comparators like `>=`; this will use Erlang term comparison which doesn't work the way you'd expect it to.

  * See also: https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types


## Assets & Brunch

- See http://www.phoenixframework.org/docs/static-assets
- Brunch handles compiling JS, CSS, and images
- `web/static/assets/` is for assets that should not be precompiled. They're just served up wholesale with no alteration.
- `web/static/js/app.js` - manifest ES6 file loaded at the end of `layout.html.eex`
- `web/static/vendor` is for 3rd-party dependencies. These are all auto included at the bottom of layout.html.eex.
- `brunch watch` - auto-runs when you start the phoenix server


## Debugging

- `IO.puts("arbitrary string")`
- `IO.inspect(value)`
- Run IEx.pry:
  * In `config/test.exs`, set `:ownership_timeout` to a large value so db connections don't time out while prying
  * Add `require IEx` to the target file
  * Insert `IEx.pry` at the target line
  * Run the tests in iex: `iex -S mix test --trace`
- You can inspect any Hex dependency code in `deps/`. You can even alter the code of a dependency, run `mix deps.compile`, then restart the Phoenix server, and your changes will be live.
- Print a query as SQL: `Ecto.Adapters.SQL.to_sql(:all, Repo, query)`


## Tests

Useful diagnostics in integration tests:

- `tail -f log/test.log`
- `IO.inspect(page_source())`
