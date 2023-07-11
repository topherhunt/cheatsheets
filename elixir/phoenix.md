# Phoenix

## References

- https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html
- Use `mix phx.gen.html` to generate a scaffolded resource & see examples of how to use the core components, eg .link and .table.











# ========= OLD ============

## Env

  * Standard envs are `dev`, `test`, and `prod`.
  * Check the current env: `Mix.env()`
  * Set the env for a command: `MIX_ENV=test mix ecto.reset`
  * Your deps always run in `prod` regardless of your main app's environment.


## Routes: Best practices

  * Err on the side of using the `resources` macro rather than manually defining each route.
  * Err on the side of flat and familiar route structures rather than nested and specialized route structures.


## Contexts

  * Rather than your controllers etc. having direct access to query & write persisted data using your schemas, Phoenix uses *context* modules as an internal boundary. All interactions between a schema and the outside world should happen only through its publicly-exposed context functions.

  * Example breakdown: A high-traffic production Phoenix app (for local event announcements & registrations) has ended up with the following 8 contexts: `auth`, `email`, `faq`, `newsletter`, `pdf`, `registration`, `ticketing`, and `support`. Together these contexts contain ~ 50 schemas total.


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


## Tests

How to test controller file uploads: https://stackoverflow.com/a/33871714/1729692

Useful diagnostics in integration tests:

- `tail -f log/test.log`
- `IO.inspect(page_source())`
