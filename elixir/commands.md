# Useful commands for Elixir / Phoenix / Mix


## Run a console, script, or function

    # start a bare iex console (not within the project context)
    iex

    # start an iex console in this project (w all dependencies loaded)
    iex -S mix

    # run a specific script
    # (args can be accessed via `System.argv()`)
    mix run priv/repo/seeds.exs

    # run a specific function
    mix run -e MyApp.Module.execute_some_function("one")


## Dependencies

    # installs all deps and lists current version of each
    mix deps.get

    # updates all deps to latest version (within constraints)
    mix deps.update --all

    # recompile deps if you've manually modified their code
    mix deps.compile


## Code formatting

    mix format # be careful what you wish for


## Phoenix

    mix phx new app_name (syntax?)

    # Generate a context, schema, and scaffold controller / templates
    mix phx.gen.html Accounts User users name:string email:string password_hash:string last_signed_in_at:utc_datetime

    mix phx.server


## Ecto

    mix ecto.create

    mix ecto.migrate

    mix ecto.rollback

    mix ecto.drop

    mix ecto.gen.migration create_user

    MIX_ENV=test mix ecto.reset


## Tests

    # run test suite (auto migrates db first)
    mix test

    # run test suite with pry debugging enabled
    # (add `IEx.pry` to your code to open a debugger there)
    iex -S mix test --trace

    # run just a single test file
    mix test path/to/folder/or/file.exs

    # run just a single test
    mix test path/to/folder/or/file.exs:31


## Phoenix app: Common setup workflow
(TODO: This probably belongs in a "How to spin up a new Phx app" guide)

    mix phx new app_name # (syntax?)

    # Update dependencies as needed

    mix deps.get

    # Update JS config & dependencies as needed

    cd assets/ && npm install

    mix ecto.create

    mix ecto.gen.migration create_user

    # Fill in the migrations & schemas for any new models

    mix ecto.migrate

    mix test

    mix phx.server


## Help & docs

    # list ALL mix tasks & generators
    mix help

    # show docs for a particular task
    mix help phx.gen.schema

    # open docs on a package (e.g. elixir, mix, phoenix, ecto)
    # (alias of `mix hex.docs open --offline PACKAGE_NAME`)
    hexdocs PACKAGE_NAME

