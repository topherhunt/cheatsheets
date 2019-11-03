# Starting up a new Phoenix app

See also:

  * https://hexdocs.pm/phoenix/up_and_running.html (incomplete, but useful)
  * https://hexdocs.pm/phoenix/heroku.html


## Basic package & system setup

  * Ensure Erlang & Elixir are installed
  * Ensure you have the latest phx_new archive:
    `mix archive.install hex phx_new 1.4.9`


## Create the app

  * Create it:

    ```
    mix phx.new my_app # DO fetch and install dependencies.
    cd my_app
    subl .
    git init .
    git add .
    git commit -m "Initial commit"
    ```

  * Update `mix.exs`:

    - Set the desired Elixir version
    - Set Phoenix version to "1.4.6" to avoid the Phoenix.Controller log config bug
    - Install Hound (optional): `{:hound, "~> 1.0", only: :test}`
    - Install Rollbax (optional): `{:rollbax, "~> 0.10"}`

  * Fetch dependencies: `mix deps.get`

  * Update `.formatter.exs` config, if you care to

  * Add `.tool-versions` to configure asdf:

    ```
    # asdf tool version specification
    # To use it:
    #   * Install asdf: https://asdf-vm.com/#/core-manage-asdf-vm
    #   * `asdf plugin install erlang`
    #   * `asdf plugin install elixir`
    #   * Install Erlang deps: https://github.com/asdf-vm/asdf-erlang#before-asdf-install
    #   * Run `asdf install` (watch for any errors during Erlang build!
    #   * Run your normal `mix` and `iex` commands as you normally would

    erlang 21.0.6
    elixir 1.8.1-otp-21
    ```

  * Run `asdf install` to make sure those versions are installed

  * Ensure the following are in .gitignore:

    ```
    # Sensitive env vars
    config/secrets.exs

    # Temp files
    .DS_Store
    *.log
    ```

Next, set up your `config/` files as needed. Here's my standard setup:

  * Update `config.exs` with my standard setup:

    - Add `H.env` helper:
      (Remember that my H.env! strategy is incompatible with Elixir releases.)

      ```rb
      # Helper for fetching env variables (incompatible with best-practice Elixir releases)
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

    - Disable the logger `request_id` data by commenting `metadata: [:request_id]`

  * Update `dev.exs`:

    - Remove the redundant MyApp.Repo config keys (only keep `show_sensitive_data...`)

    - Disable Rollbax: `config :rollbax, enabled: false`

    - Remove `config :logger, :console, format...` so dev logs look the same as prod logs

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

  * In `lib/my_app_web.ex`, in the `controller` quote block, disable Phoenix.Controller logging:

    ```rb
    def controller do
      quote do
        # NOTE: This doesn't work in phoenix 1.4.7+. Stick with v1.4.6 for now.
        use Phoenix.Controller, namespace: MyAppWeb, log: false
        # ... other stuff
    ```

  * In `lib/my_app_web/endpoint.ex`, add a new plug below `plug Plug.Telemetry`:

    ```rb
      # Custom one-line request logging
      # Must come before the session & router plugs.
      plug MyAppWeb.RequestLogger
    ```

  * Finally, add `lib/my_app_web/plugs/request_logger.ex` (see snippet).

  * Restart your server and you should see just one log line per request:

    ```
    2019-06-09 18:18:51.410 [info] ■ [PUT /manage/projects/7qDjSk/prompts/3tUrF9] params=%{"_csrf_token" => "dDVjGiIiHWUWADphMS48EXAZP34VAAAADFRcXaw/ZTx8kKPFCHr2PQ==", "_method" => "put", "_utf8" => "✓", "project_uuid" => "7qDjSk", "prompt" => %{"html" => "<div>Test question 3</div>"}, "prompt_uuid" => "3tUrF9"} user=1 (Topher Hunt) status=302 redirected_to=/manage/projects/7qDjSk duration=21ms
    ```


## One-line SQL logging

_These steps only work for Ecto v3._

In `lib/my_app/application.ex` `.start/2`, you need to set up the telemetry event. Add this snippet just before the `Supervisor.start_link/2` call:

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


## Rollbar error reporting

Above we added the :rollbax depoendency but we didn't wire up any error reporting.

  * In `router.ex`, add:

    ```rb
    # NEAR THE TOP:
    use Plug.ErrorHandler # for Rollbax

    # ... all your routes ...

    # NEAR THE BOTTOM:
    defp handle_errors(conn, data), do: WorldviewsWeb.ErrorPlugs.handle_errors(conn, data)
    ```

  * Add `lib/my_app_web/plugs/error_plugs.ex` (see snippet).

  * Celebrate.


## Assets & layout

Reference:

  * [Webpack primer](https://what-problem-does-it-solve.com/webpack/intro.html)

Steps:

  * In `dev.exs`, configure the `node` watcher so errors are easier to diagnose:

    ```rb
      ...
      "--watch-stdin",
      "--color", "--display-error-details", # <<< ADD THESE TWO FLAGS
      cd: Path.expand("../assets", __DIR__)
      ...
    ```

  * Make sure `webpack.config.js` knows where to look for modules referenced by JS that you include from hex deps:

    ```js
      // ... after the plugins setting ...
      // Make sure webpack checks here when looking for modules required by another module
      // (react-phoenix was giving errors until I added this)
      resolve: {
        modules: [path.join(__dirname, "node_modules")]
      }
    ```

  * Install Bootstrap and Jquery if desired:

    - `cd assets`
    - `npm i --save jquery`
    - `npm i --save popper.js`
    - `npm i --save bootstrap`
    - If you want Bootstrap JS: in `app.js`, add: `import "bootstrap"`
    - Whenever you want Jquery: `import $ from "jquery"` then use `$` as normal
    - In `app.css`, add `@import "../node_modules/bootstrap/dist/css/bootstrap.min.css";`
      (See https://getbootstrap.com/docs/4.0/getting-started/webpack/ to customize Bootstrap.)

  * Install SCSS support:
    (based on install steps at https://github.com/webpack-contrib/sass-loader)

    - `npm i --save sass-loader@7.1.0 node-sass`
      (sass-loader version is locked because v8 requires a different setup)
    - Replace the .css rule to `webpack.config.js` to also support scss:

      ```js
      {
        test: /\.s?css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader']
      }
      ```

    - (No need to rename `app.css`, any contained scss will be compiled by the new rule.)
    - In `dev.exs`, configure `live_reload` to also watch for `scss` extension.

  * Replace `lib/my_app_web/templates/layout/app.html.eex` with a simple Bootstrap template. (See snippet)

  * Copy my standard css styles, as relevant:
    - `layout.scss` (see snippet)
    - `utilities.scss` (see snippet)
    - Remember to declare these in `app.scss`

  * Install the Google Material iconset: https://material.io/tools/icons/?style=baseline

    - Add `icons.scss` (see snippet) and declare it in app.scss.

    - Download `MaterialIcons-Regular.woff2` from https://github.com/google/material-design-icons/tree/master/iconfont. Save it to `assets/static/fonts/`.

  * To test the CSS, replace `index.html.eex` and load the page:

    ```xml
    <h1>Title</h1>

    <div class="alert alert-success">An alert</div>

    <div class="u-card">
      A div with the "u-card" class
    </div>

    <p>Some text with <strong class="u-tooltip-target">a tooltipped section <span class="u-tooltip">The tooltip content!</span></strong></p>

    <h3>An icon: <i class="icon">face</i></h3>
    ```

  * To test Jquery, add `assets/js/utilities.js`, declare it in `app.js`, and reload the page to confirm that the body background is red:

    ```js
    import $ from "jquery"

    $(function(){
      // Smoke-test Jquery integration
      $("body").css("background-color", "red");
    })
    ```


## Misc.

  * Add my standard querying and changeset validation helpers to `repo.ex`. (see snippet)

  * Add `lib/my_app/helpers.ex` with some common helpers:

    ```rb
    defmodule MyApp.Helpers do
      def env!(key), do: System.get_env(key) || raise("Env var '#{key}' is missing!")
      def blank?(value), do: value == nil || (is_binary(value) && String.trim(value) == "")
      def present?(value), do: !blank?(value)
    end
    ```

  * Add `lib/my_app/factory.ex`: (commented out until you've built your schemas)

    ```rb
    defmodule MyApp.Factory do
      # alias MyApp.Accounts

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

      defp cast_params(params, allowed_keys) do
        params = Enum.into(params, %{})
        unexpected_key = Map.keys(params) |> Enum.find(& &1 not in allowed_keys)
        if unexpected_key, do: raise "Unexpected key: #{inspect(unexpected_key)}."
        params
      end
    end
    ```

  * Set up user accounts with email-only login. See `email_only_auth.md`.
