# Log slow Ecto queries

Use these steps to log a warning whenever a completed Ecto query took more than 1000 ms.

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
  def handle_event([:cerberus, :repo, :query], measurements, metadata, _config) do
    db_time = div(measurements.query_time, 1_000_000)

    # Log any SQL queries that take over 1000 ms.
    if db_time > 1000 || true do
      # Strip out unnecessary quotes from the query for readability
      query = Regex.replace(~r/(\d\.)"([^"]+)"/, metadata.query, "\\1\\2")
      params = inspect(metadata.params, charlists: false)
      Logger.info("SQL query took #{db_time}ms:   #{query}   [#{params}]")
    end
  end
end
```
