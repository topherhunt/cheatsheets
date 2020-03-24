
---

**DEPRECATED.**

See https://github.com/topherhunt/vanilla_phx instead.

---



# Starting up a new Phoenix app

Follow these steps to spin up a basic Phoenix app with my standard config and full email/PW auth system

See also:

  * https://github.com/topherhunt/vanilla_phx/ (the result of following these steps)
  * https://hexdocs.pm/phoenix/up_and_running.html (incomplete, but useful)
  * https://hexdocs.pm/phoenix/heroku.html


## Basic package & system setup

  * Ensure Erlang & Elixir are installed
  * Ensure you have the latest phx_new archive:
    `mix archive.install hex phx_new 1.4.11`


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

  * In `mix.exs`, set the desired Elixir version. (full version, no `~>`)

  * In `mix.exs`, install commonly-used dependencies:
    ```rb
    {:argon2_elixir, "~> 2.1.2"},
    {:bamboo, "~> 1.3"},
    {:bamboo_smtp, "~> 2.0"},
    {:floki, "~> 0.24"},
    {:nanoid, "~> 2.0"},
    {:rollbax, "~> 0.11"},
    {:timex, "~> 3.6.1"},
    {:hound, "~> 1.0", only: :test},
    ```

  * Fetch dependencies: `mix deps.get`

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
    elixir 1.8.2-otp-21
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

  * Update `config/config.exs`. See snippet. Considerations:
    - Add the `H.env` helper
    - Load `config/secrets.exs` if available
    - Set global default config for the Repo / db connection
    - Configure Bamboo for local sending by default
    - Replace the hard-coded `secret_key_base` string with `H.env!("SECRET_KEY_BASE")`
    - Comment out the logger setting `metadata: [:request_id]` (not useful to me lately)

  * Update `dev.exs` as follows:
    - Remove the redundant MyApp.Repo config keys (only keep `show_sensitive_data...`)
    - Disable Rollbax: `config :rollbax, enabled: false`
    - Remove `config :logger, :console, format...` so dev logs look the same as prod logs
    - Configure the node watcher to make errors easier to diagnose.
      After `"--watch-stdin"`, add: ` "--color", "--display-error-details", `

  * Update `config/test.exs`. See snippet. Considerations:
    - Update the Repo config to only set :pool and :ownership_timeout
    - Update the Endpoint config to `server: true` and port `4001`
    - Configure Hound
    - Disable Rollbax

  * Update `config/prod.exs`. See snippet. Considerations:
    - Ensure the Endpoint config requires https
    - Configure Bamboo to send emails using SMTP credentials by a provider such as Mailgun
    - Configure Rollbax
    - Remove the unneeded `import_config "prod.secret.exs"` line at the end

  * Delete `prod.secret.exs`.

  * Write `config/secrets.exs.template`, updating the list of env vars to match your needs. (See snippet)

  * Then COPY `secrets.exs.template` to `secrets.exs` and fill in any local (dev) values.

  * In `endpoint.ex`, update your Plug.Session config to use same-site cookies:
    - `plug Plug.Session, ... extra: "SameSite=Lax"`

  * In `application.ex` at the top of `start/2`, log the environment versions so you never have to wonder what Elixir/OTP versions are running:

    ```rb
    build_info = Map.take(System.build_info, [:build, :otp_release])
    Logger.info "#{__MODULE__}: Starting. #{inspect(build_info)}"
    ```

  * In `router.ex`, add a dev-only route for previewing sent emails:

    ```rb
    # In dev, preview all "sent" emails at localhost:4000/sent_emails
    if Mix.env == :dev do
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
    ```

  * Copy snippet: `lib/my_app/mailer.ex`. (the Bamboo config lines rely on this)

Then commit all these changes to git. Ensure `config/secrets.exs` is ignored!

Create the db: `mix ecto.create`


## One-line request logging

Useful references for logging in Elixir & Phoenix:

  * https://hexdocs.pm/logger/1.8/Logger.html
  * https://github.com/elixir-plug/plug/blob/v1.8.0/lib/plug/logger.ex
  * https://www.verypossible.com/blog/thoughtful-logging-in-elixir-a-phoenix-story

Follow these steps to set up one-line logging for a Phoenix app.

  * In `application.ex`, in the `start/2` function, detach the telemetry handlers that Phoenix attaches for you by default. (Call `:telemetry.list_handlers([])` to see all attached listeners.)

    ```rb
    def start(_type, _args) do
      # ...

      # vvv ADD THESE vvv
      :ok = :telemetry.detach({Phoenix.Logger, [:phoenix, :socket_connected]})
      :ok = :telemetry.detach({Phoenix.Logger, [:phoenix, :channel_joined]})
      :ok = :telemetry.detach({Phoenix.Logger, [:phoenix, :router_dispatch, :start]})

      # ...
      Supervisor.start_link(children, opts)
    ```

  * In `lib/my_app_web/endpoint.ex`, comment out the `Plug.Telemetry` plug.

  * In `lib/my_app_web/endpoint.ex`, add this custom plug just before Plug.Session:

    ```rb
      # One-line request logging. Must come before the session & router plugs.
      plug MyAppWeb.RequestLogger
    ```

  * Finally, add `lib/my_app_web/plugs/request_logger.ex` (see snippet).

  * Restart your server and you should see just one log line per request:

    ```
    2019-06-09 18:18:51.410 [info] ■ [PUT /manage/projects/7qDjSk/prompts/3tUrF9] params=%{"_csrf_token" => "dDVjGiIiHWUWADphMS48EXAZP34VAAAADFRcXaw/ZTx8kKPFCHr2PQ==", "_method" => "put", "_utf8" => "✓", "project_uuid" => "7qDjSk", "prompt" => %{"html" => "<div>Test question 3</div>"}, "prompt_uuid" => "3tUrF9"} user=1 (Topher Hunt) status=302 redirected_to=/manage/projects/7qDjSk duration=21ms
    ```

(Note: A new preferred way would be to `:telemetry.attach` to the `[:phoenix, :router_dispatch, :stop]` event that Phoenix is already emitting. This provides all the data we'd need; see https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#module-instrumentation for more detail.)


## One-line SQL logging

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

Above we added the :rollbax dependency but we didn't wire up any error reporting.

  * In `router.ex`, add:

    ```rb
    # (NEAR THE TOP:)
    use Plug.ErrorHandler # for Rollbax

    # ... all your routes ...

    # (NEAR THE BOTTOM:)
    # # Callback for Plug.ErrorHandler
    defp handle_errors(conn, data), do: MyAppWeb.ErrorPlugs.handle_errors(conn, data)
    ```

  * Add `lib/my_app_web/plugs/error_plugs.ex` (see snippet).

  * Celebrate.


## Assets & layout

Reference:

  * [Webpack primer](https://what-problem-does-it-solve.com/webpack/intro.html)

Steps:

  * Make sure `webpack.config.js` knows where to look for modules referenced by JS that you include from hex deps:

    ```js
      // ... after the plugins setting ...
      // Make sure webpack checks here when looking for modules required by another module
      // (react-phoenix was giving errors until I added this)
      resolve: {
        modules: [path.join(__dirname, "node_modules")]
      }
    ```

  * Install Bootstrap and Jquery (if desired):

    - `cd assets`
    - `npm i --save jquery`
    - `npm i --save popper.js`
    - `npm i --save bootstrap`
    - If you want Bootstrap JS: in `app.js`, add: `import "bootstrap"`
    - Whenever you want Jquery: `import $ from "jquery"` then use `$` as normal
    - In `app.css`, add `@import "../node_modules/bootstrap/dist/css/bootstrap.min.css";`
      (See https://getbootstrap.com/docs/4.0/getting-started/webpack/ to customize Bootstrap.)
    - Delete `phoenix.css` and import it into `app.css`.
    - Add `assets/js/jquery_utilities.js` (see snippet), and import it into `app.js`.

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

  * To test that the CSS, JS, and icons are working as expected, replace `...web/templates/page/index.html.eex` (see snippet).


## Full email/PW auth system

These steps will build out a full email/PW login system with registration, login, logout, session expiration, password confirmation, account locking (brute-force attack protection), existing email account discovery protection, token replay attack protection, password reset feature, and features for updating email or password.

Some of this code could be cut out by integrating an auth provider like Auth0. But this app would still need to handle enough auth- and session-related considerations that I might as well handroll all of it and avoid the external dependency.

See also WVJ commit `d4c260c`.

Migrations:

  * `mix ecto.gen.migration CreateUsers`. See snippet: `priv/repo/migrations/01_create_users.exs`.
  * `mix ecto.gen.migration CreateLoginTries`. See snippet: `priv/repo/migrations/02_create_login_tries.exs`.
  * `mix ecto.gen.migration CreateNonces`. See snippet: `priv/repo/migrations/03_create_nonces.exs`.
  * `mix ecto.migrate`

Context & schemas:

  * Copy snippet: `lib/my_app/data/data.ex`, the basic context for account-related schemas.
  * Copy snippet: `lib/my_app/data/user.ex`, the User schema.
  * Copy snippet: `lib/my_app/data/login_try.ex`, the LoginTries schema.
  * Copy snippet: `lib/my_app/data/nonce.ex`, the Nonce schema.

Controllers & plugs:

  * In `lib/my_app_web/router.ex`, add all auth & user routes. See snippet: `lib/my_app_web/router.ex`. Also add :load_current_user to the browser pipeline.
  * Copy snippet: `lib/my_app_web/plugs/auth_plugs.ex`.
  * Copy snippet: `lib/my_app_web/plugs/sentry_plugs.ex`.
  * Copy snippet: `lib/my_app_web/controllers/auth_controller.ex`. This contains all auth-related endpoints.
  * Copy snippet: `lib/my_app_web/controllers/user_controller.ex`. This contains endpoints for updating account settings.

Views & templates

  * Copy snippet: `lib/my_app_web/views/auth_view.ex`
  * Copy snippet: `lib/my_app_web/views/user_view.ex`
  * Copy snippet: `lib/my_app_web/views/emails_view.ex`
  * Copy snippet: `lib/my_app_web/views/form_helpers.ex`
  * Copy snippet: `lib/my_app_web/templates/layout/email.html.eex`
  * Copy all auth templates snippets: `lib/my_app_web/templates/auth/*`
  * Copy all email templates snippets: `lib/my_app_web/templates/emails/*`
  * Copy snippet: `lib/my_app_web/templates/user/edit.html.eex`
  * In `lib/my_app_web/my_app_web.ex`, in the `view` quote, add: `import MyAppWeb.FormHelpers`

Email sending:

  * Copy snippet: `lib/my_app/emails.ex`

Tests:

  * Copy snippet: `lib/my_app/factory.ex`
  * Copy snippet: `test/support/conn_helpers.ex`
  * Copy snippet: `test/support/email_helpers.ex`
  * In `test/support/data_case.ex`, in the quote block, add: `alias MyApp.Factory`
  * In `test/support/conn_case.ex`, in the quote block, add:
    - `alias MyApp.Factory`
    - `import MyAppWeb.ConnHelpers`
    - `import MyAppWeb.EmailHelpers`
  * Copy snippet: `test/support/integration_case.ex`
  * Copy snippet: `test/support/integration_helpers.ex`
  * Copy snippet: `test/my_app_web/controllers/auth_controller_test.exs`
  * Copy snippet: `test/my_app_web/controllers/user_controller_test.exs`


## Cleaning up

  * Add my standard querying and changeset validation helpers to `repo.ex`. (see snippet)

  * Add `lib/my_app/helpers.ex` with some common helpers. (see snippet)

  * Search for any forgotten mentions of `my_app` or `MyApp` in your project and replace it with your app name.

  * Run `mix test`. Around 30 tests should run; all should pass.
