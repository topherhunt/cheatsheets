## Setup

- `mix phoenix new app_name`
- `mix deps.get`
- `npm install`

## Running the server, console, and tasks

- `mix phoenix.server` - start the server
- `mix phoenix.routes`
- `mix phoenix.gen.html Video videos user_id:references:users url:string title:string description:text`
- `mix phoenix_haml.gen.html User users name:string age:integer`
  (generates haml templates, not eex)
- `mix phoenix.gen.model Category categories name:string`
- `iex -S mix` - run iex in context of this project
- `iex -S mix phoenix.server` - run contextual iex AND start the server
- `mix run -e MyApp.Module.execute_some_function("one")`
- `mix run priv/repo/seeds.exs` - you can run any arbitrary .exs script this way

## Database

- `mix ecto.create`
- `mix ecto.gen.migration create_user`
- `mix ecto.migrate`
- `mix ecto.rollback`
- `mix ecto.drop`
- `mix ecto.reset` - drops, creates, migrates, and seeds
- `MIX_ENV=test mix ecto.reset_test` - no seeds
- `mix run priv/repo/seeds.exs `

## Tests

- `mix test` - runs test suite (auto migrates db first)
- `mix test --trace`
- `mix test path/to/folder/or/file.exs`
- `mix test path/to/folder/or/file.exs:31` - run just a single test

## Mix package commands

- `mix help` - more mix commands
- `mix run path/to/file.exs` - execute an arbitrary script
- `mix hex.docs open --offline hound` - opens the docs for any package
