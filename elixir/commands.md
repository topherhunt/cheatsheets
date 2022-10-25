# Useful commands for Elixir / Mix


## Running code

  * `iex` - start a bare iex console (not within the project context)

  * `iex -S mix` - start a console within this project
    - all dependencies will be loaded, all modules will be available

  * `mix run priv/repo/do_a_thing.exs` - run a script within this project context
    - The script will have access to all dependencies, modules, etc.
    - Access script args via `System.argv()`

  * `mix run -e MyApp.Module.some_function("one")` - run a specific function in your code


## Dependencies

  * `mix deps.get` - install all deps and list installed version of each

  * `mix deps.update --all` - update all deps to the latest version (within constraints)

  * `mix deps.compile` - recompile all deps
    - Useful if you've modified a dep's source code for debugging purposes.

  * `mix deps.compile --force` - force-recompile all deps
    - Useful if you're seeing nonsensical "undefined function" errors. (corrupt state?)

  * `mix deps.clean --unused --unlock` - delete all unused deps from `mix.lock`. Useful if you've removed a dependency from `mix.exs` and really want it gone.


## Formatting

  * `mix format` - format all your code. Be careful what you wish for!


## Ecto

  * `mix ecto.create`

  * `mix ecto.migrate`

  * `mix ecto.rollback`

  * `mix ecto.drop`

  * `mix ecto.gen.migration create_user`

  * `MIX_ENV=test mix ecto.reset`


## Tests

  * `mix test` - run the whole test suite

  * `mix test path/to/folder/or/file.exs:31` - run just a single test

  * `mix test --trace` - runs tests in "trace" mode (verbose, all tests synchronous)
    - Can help detect whether a flap is due to a race condition since async is disabled.

  * Add a debugger to your test:
    - Add `IEx.pry()` to your code
    - Ensure that module has `require IEx`
    - Run tests in interactive mode: `iex -S mix test --trace`


## Help & docs

  * `mix help` - list all available mix tasks

  * `mix help phx.gen.schema` - show docs for a task

  * `mix hex.docs open --offline ecto_sql` - open the docs for a package (and cache them)
    - (I have it aliased to `hexdocs ecto_sql`)
