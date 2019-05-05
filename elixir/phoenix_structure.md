# Phoenix: Structure, components, tips


## Env

- A default Phoenix app has 3 environments: dev, test, prod. Any dependency applications (e.g. Logger) are always run in `:prod` even if your Phoenix app is in `:dev`. Check the current env with `Mix.env`.
- Override the mix env: `MIX_ENV=test mix run blah/blah.exs`


## Controller

- Phoenix uses the Plug library. All middleware (including your controller action itself) is just a series of plugs. After each plug, Phoenix checks if `conn` is halted. If so, it skips all further plugs (including the controller action) and returns the response as-is.
- The `conn` struct is big, but its keys fit in 3 categories: request fields (eg. host, method, path_info, req_headers, scheme), response fields (eg. resp_body, resp_cookies, resp_headers, status), and lazy fields (eg. cookies, params, assigns, halted)
- Transforms a request into a response plus side effects. Side effects should be invoked from the controller layer, not the schemas or views.
- Avoid nested conditionals & complex logic in controller actions using `with` and by extracting most operations to one or more Context module.
- When referencing request `params`, use strings for keys. Only use atoms internally where I'm guaranteed to have a finite number of them; atoms aren't garbage-collected.
- Web development should be supremely boring. There should be no sexy, interesting, intricate controllers; controllers should mostly tell subtle variations of the same story (e.g. CRUD).


## Views & templates

Rendering things from console:
- `Phoenix.View.render_to_string(MyApp.UserView, ​"user.html"​, user: user)`
- `Phoenix.HTML.Link.link("name", to: "path", method: :post)`

Troubleshooting:
- Avoid complex logic & chained functions in templates; extract these to view helpers. Exceptions in templates can be tough to track down.
- `.haml` template syntax: see the https://github.com/nurugger07/calliope markup guide to ensure I'm using the right syntax for Elixir embeds.
- Also, I can hack the `phoenix_haml` dependency to print out the `eex` string compiled by Calliope; often this makes it obvious why the eex parser is complaining. (Need to run `mix deps.compile` after changing code in deps.)

Form helpers:

    = form_for @changeset, @action, fn f -> do ...
    = label f, :field_name, class: "classes"
    = text_input f, :field_name, class: "classes"
    = textarea f, :field_name, class: "classes"
    = hidden_input f, :field_name, value: "value", class: "classes"
    = select f, :field_name, [{"label", val}, ...], prompt: "Select one", class: "classes"
    = error_tag f, :field_name
    = submit "Submit", class: "classes"


# Contexts

* Every subfolder under lib/[app]/ is a context. There are no longer subfolders here that aren't contexts of your application. It's the new organizing principle (apart from the web sub-app which is its own standard-structure context).
* Once you get the context boundary and name roughly right, as you call functions on that context from the outside world, you can sense the right-ness; that context feels like the right, expressive way to communicate what the code is trying to do.
* A high-traffic production Phoenix app (for local event announcements & registrations) has ended up with the following contexts: auth, email, faq, newsletter, pdf, registration, ticketing, support. The lead dev finds those boundaries very clean & natural.
* Guideline: Only the Context modules should reference Ecto.Query or Repo.


## Ecto, schemas, Repo

- Declare a field as `virtual: true` so it won't be persisted.
- Declare a field as type `{:array, :string}` to make it a List of that value type. Useful with virtual attrs.
- Lifecycle hooks: You can add `:on_delete` behavior to the db layer (during migration) or to the schema's association (less performant)
- Best practice: Mention all indexes and constraints as comments in the `schema` block, since Phoenix doesn't have a `schema.rb` equivalent.

Changesets:

- Warning: If you misspell a field in a validation macro, *it will silently skip that field*. Ensure test coverage of all validations.
- Another warning: `*_constraint` functions simply catch db-layer constraint errors and convert them to friendly object validation error messages; if you haven't added the corresponding db-layer constraint, these functions will have no effect.
- See `Ecto.Changeset` docs for full list of validation and constraint functions available.

Associations:

- During a query, pipe through `|> Ecto.preload(:videos)` to preload an association
- `user = Repo.preload(user, :videos)` - returns the `user` with `user.videos` populated
- `videos = Ecto.assoc(user, :videos)` - returns the associations as a list
- Fetching nested associations: `Ecto.assoc(post, [:comments, :author]`

**Floats & Decimals**:

- Use Float when you can get away with it. Only use Decimal when you need absolute precision of values.
- Elixir has no built-in support for decimals, you need to add the Decimal dep for that. Decimal has a somewhat verbose api since the standard arithmetic functions aren't compatible with this numeric type.
- For more docs on using floats & decimals in Ecto, see docs for Ecto.Schema.html#module-primitive-types.
- **Watch out:** If using Decimals, use `Decimal.cmp/2` to compare values. Never use kernel comparators like `>=`; this appears to work, but will use Erlang term comparison, and won't compare based on the actual numeric values.


## Assets & Brunch

- See http://www.phoenixframework.org/docs/static-assets
- Brunch handles compiling JS, CSS, and images
- `web/static/assets/` is for assets that should not be precompiled. They're just served up wholesale with no alteration.
- `web/static/js/app.js` - manifest ES6 file loaded at the end of `layout.html.eex`
- `web/static/vendor` is for 3rd-party dependencies. These are all auto included at the bottom of layout.html.eex.
- `brunch watch` - auto-runs when you start the phoenix server


## Email

- Use Bamboo and Bamboo.Test
- See the Zb app for thorough examples of mail templates, sending, and both unit tests and integration tests (which turned out to be easy to set up).


## Background jobs

- Verk (https://github.com/edgurgel/verk) is the equivalent of Sidekiq. It builds an abstraction on Elixir's processes system and provides a high-level interface for enqueuing or scheduling jobs backed in Redis, handling errors with exponential backoff, web dashboard, etc.
- Scheduled jobs MUST be idempotent.


## Logging

By default, a Phoenix app spits all logs to STDOUT. In the test environment etc., you can use the `logger_file_backend` library to route logs to a file.

See: https://github.com/onkel-dirtus/logger_file_backend


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
