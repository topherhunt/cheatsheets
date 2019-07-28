# Starting up a new Phoenix app

See also:

  * https://hexdocs.pm/phoenix/up_and_running.html (incomplete, but useful)
  * https://hexdocs.pm/phoenix/heroku.html


## Basic package & system setup

  * Ensure Erlang & Elixir are installed
  * Ensure you have the latest phx_new archive:
    `mix archive.install hex phx_new 1.4.9`


## Create the app

Create it:

    mix phx.new my_app # DO fetch and install dependencies.
    cd my_app
    subl .
    git init .
    git add .
    git commit -m "Initial commit"

Review `mix.exs`:

  * Set the Elixir version
  * Ensure Phoenix is <= 1.4.6 to avoid the Phoenix.Controller log config bug
  * Install Hound (optional): `{:hound, "~> 1.0", only: :test}`
  * Install Rollbax (optional): `{:rollbax, "~> 0.10"}`

Fetch dependencies: `mix deps.get`

Update `.formatter.exs`, if you care to

Ensure the following are in .gitignore:

```
# Sensitive env vars
config/secrets.exs

# Temp files
.DS_Store
*.log
```

Set up your `config/` files as needed. Here's the full setup, which might not be relevant to quick prototype apps:

  * Update `config.exs` with my standard setup:

    - Add `H.env` helper:
      (Remember that my H.env! strategy is incompatible with Elixir releases.)

      ```rb
      defmodule H do
        def env!(key), do: System.get_env(key) || raise("Env var '#{key}' is missing!")
      end
      ```

    - Load `secrets.exs` if available:

      ```rb
      # Automatically load sensitive environment variables for dev and test
      if File.exists?("config/secrets.exs"), do: import_config("secrets.exs")
      ```

    - Configure the database connection globally:

      ```rb
      config :my_app, MyApp.Repo,
        url: H.env!("DATABASE_URL"),
        # Heroku PG hobby-dev allows max 20 db connections
        pool_size: 10,
        log: false
      ```

    - Replace the hard-coded `secret_key_base` string with `H.env!("SECRET_KEY_BASE")`.

    - Disable Rollbax: `config :rollbax, enabled: false`

  * Update `dev.exs`:

    - Remove the redundant MyApp.Repo config keys (only keep `show_sensitive_data...`)

    - Disable Rollbax: `config :rollbax, enabled: false`

  * Update `test.exs`:

    - Update the Repo config:

      ```rb
      config :my_app, MyApp.Repo,
        pool: Ecto.Adapters.SQL.Sandbox,
        # long timeout to allow debugging in tests
        ownership_timeout: 20 * 60 * 1000
      ```

    - Update `MyAppWeb.Endpoint` to `server: true` and port `4001` for Hound:

      ```rb
      config :my_app, MyAppWeb.Endpoint,
        http: [port: 4001],
        server: true
      ```

    - Configure Hound: `config :hound, driver: "chrome_driver", browser: "chrome_headless"`

    - Disable Rollbax: `config :rollbax, enabled: false`

  * Update `prod.exs`:

    - Update the Endpoint config to require https:

      ```rb
      config :my_app, MyAppWeb.Endpoint,
        http: [:inet6, port: System.get_env("PORT") || 4000],
        url: [scheme: "https", host: H.env!("HOST_NAME"), port: 443],
        force_ssl: [rewrite_on: [:x_forwarded_proto]],
        cache_static_manifest: "priv/static/cache_manifest.json"
      ```

    - Configure Rollbax:

      ```rb
      config :rollbax,
        access_token: H.env!("ROLLBAR_ACCESS_TOKEN"),
        environment: "prod"
      ```

    - Remove the unneeded `import_config "prod.secret.exs"` line.

  * Write `config/secrets.exs.template`, updating the list of sample env vars to match your needs. (See snippet)

  * Then COPY `secrets.exs.template` to `secrets.exs` and fill in any local (dev) values.

  * Delete `prod.secret.exs`.

Then commit all these changes to git. Ensure `config/secrets.exs` is ignored!

Create the db: `mix ecto.create`


## One-line request logging

Useful references for logging in Elixir & Phoenix:

  * https://hexdocs.pm/logger/1.8/Logger.html
  * https://github.com/elixir-plug/plug/blob/v1.8.0/lib/plug/logger.ex
  * https://www.verypossible.com/blog/thoughtful-logging-in-elixir-a-phoenix-story

Follow these steps to set up one-line logging for a Phoenix app.

In `lib/my_app_web.ex`, in the `controller` quote block, disable Phoenix.Controller logging:

```rb
def controller do
  quote do
    # NOTE: This doesn't work in phoenix 1.4.7+. Stick with v1.4.6 for now.
    use Phoenix.Controller, namespace: MyAppWeb, log: false
    ...
```

In `lib/my_app_web/endpoint.ex`, add a new plug below `plug Plug.Telemetry`:

```rb
  # Custom one-line request logging
  # Must come before the session & router plugs.
  plug MyAppWeb.RequestLogger
```

Finally create `lib/my_app_web/plugs/request_logger.ex` with the following content:

```rb
# One-line full request logging inspired by Plug.Logger.
# See https://github.com/elixir-plug/plug/blob/v1.8.0/lib/plug/logger.ex
# Need to restart the server after updating this file.
defmodule MyAppWeb.RequestLogger do
  require Logger

  @behaviour Plug

  def init(opts), do: opts

  def call(conn, _opts) do
    start_time = System.monotonic_time()

    Plug.Conn.register_before_send(conn, fn(conn) ->
      Logger.log(:info, fn ->
        # We don't want passwords etc. being logged
        params = inspect(Phoenix.Logger.filter_values(conn.params))
        # Clean up GraphQL query params for easier readability
        params = Regex.replace(~r/\\n/, params, " ")
        params = Regex.replace(~r/ +/, params, " ")

        ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

        # Log any important session data eg. logged-in user
        user = conn.assigns[:current_user]
        user_string = if user, do: "#{user.id} (#{user.name})", else: "(none)"

        # Note redirect, if any
        redirect = Plug.Conn.get_resp_header(conn, "location")
        redirect_string = if redirect != [], do: " redirected_to=#{redirect}", else: ""

        # Calculate time taken (always in ms for consistency
        stop_time = System.monotonic_time()
        time_us = System.convert_time_unit(stop_time - start_time, :native, :microsecond)
        time_ms = div(time_us, 100) / 10

        "■ method=#{conn.method} path=#{conn.request_path} params=#{params} "<>
        "ip=#{ip} user=#{user_string} "<>
        "status=#{conn.status}#{redirect_string} duration=#{time_ms}ms"
      end)

      conn
    end)
  end
end
```

Now restart your server and you should see each request generate one log entry (and only one), with all the basic info present:

```
2019-06-09 18:18:51.410 [info] ■ [PUT /manage/projects/7qDjSk/prompts/3tUrF9] params=%{"_csrf_token" => "dDVjGiIiHWUWADphMS48EXAZP34VAAAADFRcXaw/ZTx8kKPFCHr2PQ==", "_method" => "put", "_utf8" => "✓", "project_uuid" => "7qDjSk", "prompt" => %{"html" => "<div>Test question 3</div>"}, "prompt_uuid" => "3tUrF9"} user=1 (Topher Hunt) status=302 redirected_to=/manage/projects/7qDjSk duration=21ms
```


## One-line SQL logging

One-line SQL logging is easy to set up, but the steps change depending on whether you're on Ecto v2 or v3.


### For Ecto v2

In `config.exs`, configure MyApp.Repo to use a new custom logger function:

```rb
config :my_app, MyApp.Repo,
  # ...
  loggers: [{MyApp.Repo, :log_query, []}]
```

In `lib/my_app/repo.ex`, define the `log_query` function: (note: in my case I've hard-coded the `:debug` log level.)

```rb
  ...
  require Logger

  # Inspired by https://github.com/elixir-ecto/ecto/blob/v2.2.11/lib/ecto/log_entry.ex
  def log_query(entry) do
    Logger.log(:debug, fn ->
      {ok, _} = entry.result
      source = inspect(entry.source)
      time_us = System.convert_time_unit(entry.query_time, :native, :microsecond)
      time_ms = div(time_us, 100) / 10
      # Strip out unnecessary quotes from the query for readability
      query = Regex.replace(~r/(\d\.)"([^"]+)"/, entry.query, "\\1\\2")
      params = inspect(entry.params, charlists: false)

      "SQL query: #{ok} source=#{source} db=#{time_ms}ms   #{query}   params=#{params}"
    end)
  end
```


### For Ecto v3

In `lib/my_app/application.ex` `MyApp.Application.start/2`, you need to set up the telemetry event. Add this snippet just before the `Supervisor.start_link/2` call:

```rb
    # Subscribe to Ecto queries for logging
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

In `config/config.exs`, configure MyApp.Repo to disable the standard Ecto logging:

```rb
config :my_app, MyApp.Repo,
  # ...
  log: false
```

Finally, in `config/dev.exs`, optionally set log_level to `:debug` to include these logs:

```rb
config :logger, level: :debug
```


## Assets & layout

Reference:

  * [Webpack primer](https://what-problem-does-it-solve.com/webpack/intro.html)

In `dev.exs`, configure the `node` watcher so errors are easier to diagnose:

```rb
  ...
  "--watch-stdin",
  "--color", "--display-error-details", # <<< ADD THESE TWO FLAGS
  cd: Path.expand("../assets", __DIR__)
  ...
```

Make sure `webpack.config.js` knows where to look for modules referenced by JS that you include from hex deps:

```js
  // ... after the plugins setting ...
  // Make sure webpack checks here when looking for modules required by another module
  // (react-phoenix was giving errors until I added this)
  resolve: {
    modules: [path.join(__dirname, "node_modules")]
  }
```

How to install Jquery and Bootstrap:

  * `cd assets`
  * `npm i --save jquery`
  * `npm i --save popper.js`
  * `npm i --save bootstrap`
  * If you want Bootstrap JS: in `app.js`, add: `import "bootstrap"`
  * Whenever you want Jquery: `import $ from "jquery"` then use `$` as normal
  * In `app.css`, add `@import "../node_modules/bootstrap/dist/css/bootstrap.min.css";`
    (See https://getbootstrap.com/docs/4.0/getting-started/webpack/ to customize Bootstrap)

Install SCSS support:
(based on install steps at https://github.com/webpack-contrib/sass-loader)

  * `npm i --save sass-loader node-sass`
  * Add a .scss rule to `webpack.config.js`:

    ```js
    {
      test: /\.scss$/,
      use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader']
    }
    ```

  * Rename `app.css` to `app.scss`. This lets you `@import` either css or scss into app.scss. Remember to also update this file's reference in `app.js`. (If `app.scss` is your only css entrypoint, this makes the .css rule in webpack.config.js obsolete, but there's no harm in leaving it there.)
  * In `dev.exs`, configure `live_reload` to also watch for `scss` extension.

Replace `lib/my_app_web/templates/layout/app.html.eex` with a simple Bootstrap template. (See snippet)

Copy my custom css from RTL, as relevant:

  * layout.scss (contains styles for the sticky footer)
  * overrides.scss
  * utilities.css
  * (ensure each one is declared in app.css)

Install the Google Material iconset: https://material.io/tools/icons/?style=baseline

  * Copy `icons.css` from RTL (and declare it in `app.css`)
  * Download or copy `MaterialIcons-Regular.woff2` to `assets/static/fonts/`

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

```xml
<h1>Title</h1>

<div class="alert alert-success">An alert</div>

<div class="u-card">
  A div with the "u-card" class
</div>

<div class="u-card js-fade-on-click">Jquery test: click me to fade</div>

<h3>An icon: <i class="icon">face</i></h3>
```


## Misc.

  * In `repo.ex`, add my standard helpers:

    ```rb
    import Ecto.Query

    def count(query), do: query |> select([t], count(t.id)) |> one()
    def any?(query), do: count(query) >= 1
    def first(query), do: query |> limit(1) |> one()
    def first!(query), do: query |> limit(1) |> one!()

    def ensure_success(result) do
      case result do
        {:ok, object} -> object
        {:error, changeset} -> raise Ecto.InvalidChangesetError, changeset: changeset
      end
    end
    ```

  * Write `lib/my_app/helpers.ex` with some common helpers:

    ```rb
    defmodule MyApp.Helpers do
      def env!(key), do: System.get_env(key) || raise("Env var '#{key}' is missing!")
      def blank?(value), do: value == nil || (is_binary(value) && String.trim(value) == "")
      def present?(value), do: !blank?(value)
    end
    ```

  * Write `lib/my_app/factory.ex`: (commented out until you've built your schemas)

    ```rb
    defmodule Calories.Factory do
      # alias Calories.Accounts

      # def insert_user(params \\ %{}) do
      #   assert_no_keys_except(params, [:name, :email, :password])
      #   uuid = random_uuid()

      #   Accounts.insert_user!(%{
      #     name: params[:name] || "User #{uuid}",
      #     email: params[:email] || "user_#{uuid}@example.com",
      #     password: params[:password] || uuid
      #   })
      # end

      def random_uuid, do: Nanoid.generate(8)

      #
      # Internal
      #

      defp assert_no_keys_except(params, allowed_keys) do
        keys = Enum.into(params, %{}) |> Map.keys()
        unexpected_key = Enum.find(keys, & &1 not in allowed_keys)
        if unexpected_key, do: raise "Unexpected key: #{inspect(unexpected_key)}."
      end
    end
    ```
