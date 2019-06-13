# Starting up a new Phoenix app

See also:

  * https://hexdocs.pm/phoenix/up_and_running.html (incomplete, but useful)
  * https://hexdocs.pm/phoenix/heroku.html


## Basic package & system setup

  * Ensure Erlang & Elixir are installed
  * Ensure you have the latest phx_new archive:
    `mix archive.install hex phx_new 1.4.3`


## Create the app

Create it:

    mix phx.new my_app
    # Don't install NPM packages. We'll use yarn instead of npm.
    cd my_app
    cd assets && yarn && cd ..
    subl .
    git init .
    git add .
    git commit -m "Initial commit"

Review `mix.exs` and compare against RTL. Add any deps you need.

Set up the `config/` files to use env vars: (see RTL for reference)
(Note: Env var usage isn't compatible with Distillery releases.)
Files and topics to consider:

  * config.exs:
    - define H.env!
    - load secrets.exs
    - use H.env! everywhere
    - Repo
    - oauth & ueberauth
    - filter_parameters
    - review config
  * dev.exs: review config, live_reload liveviews path, rollbax
  * test.exs: review config, Repo, Mailer, LoggerFileBackend
  * prod.exs: update prod config as relevant
  * secrets.exs: copy this file and set up all dev secrets
  * copy secrets.exs to secrets.exs.template, sanitize it, and commit it to Git

Ensure the following are in .gitignore:

    config/secrets.exs
    .DS_Store
    *.log

Update `.formatter.exs`, if you care to

Fetch dependencies: `mix deps.get`

Create the db: `mix ecto.create`


## One-line request logging

Useful references for logging in Elixir & Phoenix:

  * https://hexdocs.pm/logger/1.8/Logger.html
  * https://github.com/elixir-plug/plug/blob/v1.8.0/lib/plug/logger.ex
  * https://www.verypossible.com/blog/thoughtful-logging-in-elixir-a-phoenix-story

Follow these steps to set up one-line logging for a Phoenix app.

In `config.exs`, ensure that all sensitive params are filtered out of the logs:

```ruby
# Scrub these params from the logs
config :phoenix, :filter_parameters, ["password", "admin_password"]
```

In `lib/my_app_web.ex`, in the `controller` quote block, disable Phoenix.Controller logging:

```ruby
def controller do
  quote do
    use Phoenix.Controller, namespace: MyAppWeb, log: false
    ...
```

In `lib/my_app_web/endpoint.ex`, remove `plug(Plug.Logger)` and replace it with a new plug:

```ruby
  # Custom one-line request logging
  plug MyAppWeb.RequestLogger
```

And finally create `lib/my_app_web/plugs/request_logger.ex` with the following content:

```ruby
# One-line full request logging inspired by Plug.Logger.
# See https://github.com/elixir-plug/plug/blob/v1.8.0/lib/plug/logger.ex
# Need to restart the server after updating this file.
defmodule MyAppWeb.RequestLogger do
  require Logger

  @behaviour Plug

  def init(opts) do
    %{log_level: opts[:log_level] || :info}
  end

  def call(conn, opts) do
    start_time = System.monotonic_time()

    Plug.Conn.register_before_send(conn, fn(conn) ->
      # Uses a func so the string doesn't need to be computed unless log_level is active.
      # Charlist would be more performant, but I'm not pro enough to worry about that.
      # Other data I could include, but feels redundant: remote_ip, port, owner (PID).
      Logger.log(
        opts.log_level,
        fn ->
          "■ [#{conn.method} #{conn.request_path}] "<>
          "params=#{inspect(Phoenix.Logger.filter_values(conn.params))} "<>
          "user=#{print_user(conn)} "<>
          "status=#{conn.status}#{print_redirect(conn)} "<>
          "duration=#{print_time_taken(start_time)}"
        end)
      conn
    end)
  end

  defp print_user(conn) do
    if conn.assigns.current_user do
      "#{conn.assigns.current_user.id} (#{conn.assigns.current_user.name})"
    else
      "(none)"
    end
  end

  defp print_redirect(conn) do
    if conn.status == 302 do
      " redirected_to=#{Plug.Conn.get_resp_header(conn, "location")}"
    else
      ""
    end
  end

  defp print_time_taken(start_time) do
    stop_time = System.monotonic_time()
    microsecs = System.convert_time_unit(stop_time - start_time, :native, :microsecond)

    if microsecs > 1000 do
      [microsecs |> div(1000) |> Integer.to_string(), "ms"]
    else
      [Integer.to_string(microsecs), "µs"]
    end
  end
end
```

Now restart your server and you should see each request generate one log entry with all the basic info present (and no redundant chaff lines):

```
2019-06-09 18:18:51.410 [info] ■ [PUT /manage/projects/7qDjSk/prompts/3tUrF9] params=%{"_csrf_token" => "dDVjGiIiHWUWADphMS48EXAZP34VAAAADFRcXaw/ZTx8kKPFCHr2PQ==", "_method" => "put", "_utf8" => "✓", "project_uuid" => "7qDjSk", "prompt" => %{"html" => "<div>Test question 3</div>"}, "prompt_uuid" => "3tUrF9"} user=1 (Topher Hunt) status=302 redirected_to=/manage/projects/7qDjSk duration=21ms
```


## One-line SQL logging

One-line SQL logging is easy to set up, but the steps change depending on whether you're on Ecto v2 or v3.


### For Ecto v2

In `config.exs`, configure MyApp.Repo to use a new custom logger function:

```ruby
config :my_app, MyApp.Repo,
  # ...
  loggers: [{MyApp.Repo, :log_query, []}]
```

In `lib/my_app/repo.ex`, define the `log_query` function:

```
  # ...
  require Logger

  # Inspired by https://github.com/elixir-ecto/ecto/blob/v2.2.11/lib/ecto/log_entry.ex
  def log_query(entry) do
    Logger.log(:debug, fn ->
      {ok, _} = entry.result
      source = if entry.source, do: " source=#{inspect(entry.source)}", else: ""
      time_us = System.convert_time_unit(entry.query_time, :native, :microsecond)
      time_ms = div(time_us, 100) / 10
      query = Regex.replace(~r/(\d\.)"([^"]+)"/, entry.query, "\\1\\2")

      params = Enum.map(entry.params, fn
        %Ecto.Query.Tagged{value: value} -> value
        value -> value
      end)

      "SQL query: #{ok}#{source} db=#{time_ms}ms   #{query}   params=#{inspect(params)}"
    end)
  end
```

In `config/dev.exs`, optionally set log_level to `:debug` to include these logs:

```ruby
config :logger, level: :debug
```


### For Ecto v3

In `lib/my_app/application.ex` `MyApp.Application.start/2`, you need to set up the telemetry event. Add this snippet just before the `Supervisor.start_link/2` call:

```ruby
    # Subscribe to Ecto queries for logging
    # See https://hexdocs.pm/ecto/Ecto.Repo.html#module-telemetry-events
    # and https://github.com/beam-telemetry/telemetry
    handler = &MyApp.Telemetry.handle_event/4
    :ok = :telemetry.attach("my_app-ecto", [:my_app, :repo, :query], handler, %{})
```

Then define your Telemetry module which for now will only have this one event handler:

```
defmodule MyApp.Telemetry do
  require Logger

  # Thanks to https://hexdocs.pm/ecto/Ecto.Repo.html#module-telemetry-events
  def handle_event([:my_app, :repo, :query], measurements, metadata, _config) do
    Logger.log(:debug, fn ->
      {ok, _} = metadata.result
      source = metadata.source || "?"
      query_time = div(measurements.query_time, 100) / 10
      query = Regex.replace(~r/(\d\.)"([^"]+)"/, metadata.query, "\\1\\2")
      params = metadata.params

      "SQL query: #{ok} source=\"#{source}\" db=#{query_time}ms   #{query}   params=#{inspect(params)}"
    end)
  end
end
```

In `config/config.exs`, configure MyApp.Repo to disable the standard Ecto logging:

```ruby
config :my_app, MyApp.Repo,
  # ...
  log: false
```

Finally, in `config/dev.exs`, optionally set log_level to `:debug` to include these logs:

```ruby
config :logger, level: :debug
```


## Assets & layout

Install Jquery and Bootstrap:

  * `cd assets`
  * `yarn add jquery`
  * `yarn add popper.js`
  * `yarn add bootstrap`
  * In `app.js`, add: `import "bootstrap"` (for basic JS features like dropdowns)
  * When you want Jquery: `import $ from "jquery"` then use $ as normal
  * In `app.css`, add `@import "../node_modules/bootstrap/dist/css/bootstrap.min.css";`
    (TODO: is there no more convenient way to link it?)
    (See https://getbootstrap.com/docs/4.0/getting-started/webpack/ to customize)

(Webpack primer: https://what-problem-does-it-solve.com/webpack/intro.html)

Install SCSS support by more or less following the steps at https://github.com/webpack-contrib/sass-loader.

Replace `lib/my_app_web/templates/layout/app.html.eex` with a simple Bootstrap template:

```
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8">
        <meta http-equiv="X-UA-Compatible" content="IE=edge">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="description" content="">
        <meta name="author" content="">
        <title>Grassflog</title>
        <link rel="stylesheet" href="<%= Routes.static_path(@conn, "/css/app.css") %>">
      </head>

      <body>
        <nav class="navbar navbar-expand-sm navbar-light bg-light">
          <%= link "My Site", to: "#", class: "navbar-brand" %>
          <button class="navbar-toggler" data-toggle="collapse" data-target="#navbar-content">
            <span class="navbar-toggler-icon"></span>
          </button>
          <div id="navbar-content" class="collapse navbar-collapse">
            <ul class="navbar-nav mr-auto"></ul>
            <ul class="navbar-nav">
              <li class="nav-item"><%= link "Log in", to: "#", class: "nav-link" %></li>
              <li class="nav-item dropdown">
                <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown">
                  <i class="icon">settings</i> <span class="caret"></span>
                </a>
                <div class="dropdown-menu dropdown-menu-right">
                  <div class="dropdown-item em small">Dropdown text</div>
                  <%= link "A link", to: "#", class: "dropdown-item text-danger" %>
                </div>
              </li>
            </ul>
          </div>
        </nav>

        <main class="container-fluid">
          <%= if get_flash(@conn, :info) do %>
            <p class="alert alert-info" role="alert"><%= get_flash(@conn, :info) %></p>
          <% end %>

          <%= if get_flash(@conn, :error) do %>
            <p class="alert alert-danger" role="alert"><%= get_flash(@conn, :error) %></p>
          <% end %>

          <%= render @view_module, @view_template, assigns %>
        </main>

        <footer class="text-center small">
          Built by <%= link "Topher Hunt", to: "http://topherhunt.com", target: "_blank" %>
        </footer>

        <script type="text/javascript" src="<%= Routes.static_path(@conn, "/js/app.js") %>"></script>
      </body>
    </html>
```

Copy my custom css from RTL, as relevant:

  * layout.css (contains styles for the sticky footer)
  * bootstrap_fixes.css
  * utilities.css
  * (ensure each one is declared in app.css)

Install the Google Material iconset: https://material.io/tools/icons/?style=baseline

  * Copy `icons.css` from RTL (and declare it in `app.css`)
  * Download or copy the .woff2 font to `assets/static/fonts/`

To test Jquery, add `assets/js/utilities.js` and declare it in `app.js`:

```js
    import $ from "jquery"

    $(function(){

      $(".js-fade-on-click").click(function(e) {
        e.preventDefault()
        $(this).fadeToggle(500)
      })

    })
```

To test that it's all wired up properly, replace `index.html.eex` and load the page:

```
    <h1>Title</h1>

    <div class="alert alert-success">An alert</div>

    <div class="u-card">
      A div with the "u-card" class
    </div>

    <div class="u-card js-fade-on-click">Jquery test: click me to fade</div>

    <h3>An icon: <i class="icon">face</i></h3>
```


## Misc.

  * Copy query helpers from RTL.Repo.
  * Copy helpers module from RTL.Helpers.
  * Rename PageController to HomeController. (controller, route, view, template, test)
  * Copy RTL.Factory. (maybe leave one insert_* func commented out for later)
  * Copy **Grassflog's** ErrorHelpers.error_tag/2 for easier controller test assertions
