# How to set up one-line SQL logging in Phoenix

By default, Ecto queries are logged over two lines like this:

```
09:57:05.784 [debug] QUERY OK source="users" db=9.9ms decode=1.6ms queue=1.0ms idle=7538.9ms
SELECT u0."id", u0."name", u0."email", u0."password_hash", u0."confirmed_at", u0."last_visit_date", u0."inserted_at", u0."updated_at" FROM "users" AS u0 WHERE (u0."id" = $1) [1]
```

_These steps only work for Ecto v3._

In `lib/my_app/application.ex` `.start/2`, add this snippet just before the `Supervisor.start_link/2` call to set up the telemetry event:

```rb
    # Subscribe to Ecto queries for logging.
    # See https://hexdocs.pm/ecto/Ecto.Repo.html#module-telemetry-events
    # and https://github.com/beam-telemetry/telemetry
    handler = &MyApp.Telemetry.handle_event/4
    :ok = :telemetry.attach("my_app_ecto", [:my_app, :repo, :query], handler, %{})
```

Then define your Telemetry module which for now will only have this one event handler. I saved mine in `lib/my_app/telemetry.ex`:

```rb
defmodule MyApp.Telemetry do
  require Logger

  # Thanks to https://hexdocs.pm/ecto/Ecto.Repo.html#module-telemetry-events
  def handle_event([:my_app, :repo, :query], measurements, metadata, _config) do
    Logger.log(:debug, fn ->
      {ok, _} = metadata.result
      source = inspect(metadata.source)
      time = div(measurements.query_time, 100_000) / 10
      # Strip out unnecessary quotes from the query for readability
      query = Regex.replace(~r/(\d\.)"([^"]+)"/, metadata.query, "\\1\\2")
      params = inspect(metadata.params, charlists: false)

      "SQL query: #{ok} source=#{source} db=#{time}ms   #{query}   params=#{params}"
    end)
  end
end
```

In your config files, adjust MyApp.Repo to disable the standard Ecto logging:

```rb
config :my_app, MyApp.Repo,
  # ...
  log: false
```

Finally, in `config/dev.exs`, set log_level to `:debug` to include these logs:

```rb
config :logger, level: :debug
```
