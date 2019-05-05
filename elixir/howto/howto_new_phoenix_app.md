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


## Logging

Reference:

  * https://www.verypossible.com/blog/thoughtful-logging-in-elixir-a-phoenix-story
  * The following will at least ensure all important data is logged in prod, but not on one line. If I really want one-line logging, I might be able to write a plug for it, but it will take some digging into Plug internals. See Phoenix.Logger.phoenix_controller_call/3 (which logs the "Processing with..." line) and Plug.Logger.call/2 (which is responsible for the "GET /path" and "Sent 200 in 10ms" log lines).

In `config.exs`, add the :filter_parameters option:

    # Scrub these params from the logs
    config :phoenix, :filter_parameters, ["password", "admin_password"]

In `rtl_web.ex`, set controller logging to :info:
(this more clearly shows logged params in dev, and ensures they're visible in prod)

    def controller do
      quote do
        use Phoenix.Controller, namespace: RTLWeb, log: :info
        ...


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


## Install scss support

TODO

(see https://getbootstrap.com/docs/4.0/getting-started/webpack/ for hints)


## Misc.

  * Copy query helpers from RTL.Repo.
  * Copy helpers module from RTL.Helpers.
  * Rename PageController to HomeController. (controller, route, view, template, test)
  * Copy RTL.Factory. (maybe leave one insert_* func commented out for later)
