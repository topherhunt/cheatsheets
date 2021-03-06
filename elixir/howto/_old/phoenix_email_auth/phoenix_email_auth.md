# Simple email-only auth system in Phoenix

Passwords are so 2018.

The broad approach is described well here: https://lukeplant.me.uk/blog/posts/a-simple-passwordless-email-only-login-system/. That article notes a few important security considerations:

  - The "send me an email link" endpoint must not fetch the user record. Behavior must be identical for new vs. existing users, namely it just emails a login link to the requested address.
  - Said login link must be signed and must expire.
  - The "confirm this address" endpoint (reached by clicking the emailed login link) must never render an HTML page. It must always redirect. This mitigates the risk inherent in including a replayable token in a GET request.
  - There must be a way for the user to log out, which destroys all their login sessions across all devices. This is what I use `user.session_token` for.


## User schema

(Adapt as needed if you already have a User schema.)

  * Create the users table:

    ```rb
    defmodule MyApp.Repo.Migrations.CreateUsers do
      use Ecto.Migration

      def change do
        create table(:users) do
          add :email, :string, null: false
          add :session_token, :string, null: false
          add :last_visit_date, :date
          timestamps()
        end

        create unique_index(:users, [:email])
      end
    end
    ```

  * Create or update a context to house your User schema, as well as helpers for writing and reading login tokens. (See snippet `context.ex`)

  * Define the User schema with changeset, logic for default token, and filter system. (See snippet `user.ex`)

  * Define `lib/my_app/factory.ex` with a User factory. (see snippet)

  * Add the Nanoid dep to `mix.exs`: `{:nanoid, "~> 2.0"},`


## Pages / endpoints / controllers / routes

  * Add `lib/...web/plugs/auth_plugs.ex`. (See snippet)

  * Add `lib/...web/controllers/auth_controller.ex`. (See snippet)

  * Add `lib/...web/views/auth_view.ex`:

    ```rb
    defmodule MyAppWeb.AuthView do
      use MyAppWeb, :view
    end
    ```

  * Add `lib/...web/templates/auth/login.html.eex`:

    ```
    <div class="u-card u-centered-600">
      <h2>Log in / register</h2>

      <p>Enter your email address, then click the button. We'll email you a secure login link.</p>

      <%= form_for @conn, Routes.auth_path(@conn, :login_submit), [method: :post], fn _f -> %>
        <div class="form-group">
          <label for="email">Email</label>
          <%= text_input :user, :email, class: "form-control" %>
        </div>
        <div class="form-group">
          <%= submit "Send me my login link", class: "btn btn-primary" %>
        </div>
      <% end %>
    </div>
    ```

  * In `router.ex`, declare the auth-related routes and make sure current_user is loaded:

    ```rb
    defmodule MyAppWeb.Router do
      # ...
      # ADD THIS:
      import MyAppWeb.AuthPlugs, only: [load_current_user: 2]

      pipeline :browser do
        # ...
        # ADD THIS:
        plug :load_current_user
      end

      # ...

      scope "/", MyAppWeb do
        # ...
        # ADD THESE:
        get "/auth/login", AuthController, :login
        post "/auth/login_submit", AuthController, :login_submit
        get "/auth/confirm", AuthController, :confirm
        get "/auth/log_out", AuthController, :log_out
      end
    end
    ```

  * In your layout `app.html.eex`, add the login & logout links to the navbar. If you're using Bootstrap you can use this snippet:

    ```
    <div id="navbar-content" class="collapse navbar-collapse">
      <ul class="navbar-nav mr-auto"></ul>
      <ul class="navbar-nav">
        <%= if @current_user do %>
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown">
              <i class="icon">person</i> <span class="caret"></span>
            </a>
            <div class="dropdown-menu dropdown-menu-right">
              <div class="dropdown-item em small">Logged in as <%= @current_user.email %></div>
              <%= link "Log out", to: Routes.auth_path(@conn, :log_out), class: "dropdown-item text-danger" %>
            </div>
          </li>
        <% else %>
          <li class="nav-item"><%= link "Log in / register", to: Routes.auth_path(@conn, :login), class: "nav-link" %></li>
        <% end %>
      </ul>
    </div>
    ```

  * To allow "force login" as another user, add `lib/my_app/tasks/login.ex` (see snippet).

  * To restrict certain controllers to logged-in users, add `plug :require_logged_in`. (may need to import AuthPlugs too)


## Set up email system (Bamboo)

  * Add bamboo and bamboo_smtp deps to `mix.exs`:

    ```rb
    {:bamboo, "~> 1.3"},
    {:bamboo_smtp, "~> 2.0"}
    ```

  * Configure Bamboo in `config.exs`:

    ```rb
    # By default, sent emails are captured in a local process for later inspection.
    # Example:
    #   MyApp.AdminEmails.unknown_heats() |> MyApp.Mailer.deliver_now()
    #   Bamboo.SentEmail.all() # => a list having one %Bamboo.Email{} struct
    config :my_app, MyApp.Mailer, adapter: Bamboo.LocalAdapter
    ```

  * Configure Bamboo in `prod.exs` using SMTP credentials by a provider like Mailgun:

    ```rb
    # See https://hexdocs.pm/bamboo_smtp/Bamboo.SMTPAdapter.html#module-example-config
    config :my_app, MyApp.Mailer,
      adapter: Bamboo.SMTPAdapter,
      server: System.get_env("SMTP_SERVER") || raise("Missing env: SMTP_SERVER"),
      username: System.get_env("SMTP_USERNAME") || raise("Missing env: SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD") || raise("Missing env: SMTP_PASSWORD"),
      port: 587
    ```

  * In `router.ex`, add a dev-only route for previewing sent emails:

    ```rb
    # In dev, preview all "sent" emails at localhost:4000/sent_emails
    if Mix.env == :dev do
      forward "/sent_emails", Bamboo.SentEmailViewerPlug
    end
    ```

  * Define a mailer module in `lib/my_app/mailer.ex`. Remember to always call `.send` rather than `.deliver_now` etc. so that low-level Erlang errors are handled:

    ```rb
    defmodule MyApp.Mailer do
      use Bamboo.Mailer, otp_app: :my_app
      require Logger

      # Use Mailer.send rather than Mailer.deliver_now etc. SMTP failures may raise low-level
      # ErlangErrors which aren't handled well by default.
      def send(email) do
        try do
          deliver_now(email)
          {:ok}
        catch e ->
          Logger.warn "Error sending email #{inspect(email.subject)} to #{inspect(email.to)}: #{inspect(e)}"
          {:error, e}
        end
      end
    end
    ```

  * Add an Emails module with a function for building the confirmation email. (See snippet `emails.ex`)

  * Add the view that this mailer will use for rendering, at `lib/...web/views/emails_view.ex`:

    ```rb
    defmodule MyAppWeb.EmailsView do
      use MyAppWeb, :view
    end
    ```

  * Add a template for this email at `lib/...web/templates/emails/confirm_address.html.eex`:

    ```xml
    <h1>Worldview Journeys: Your special login link</h1>

    <p>Please click the link below to log in.</p>

    <p><%= link @url, to: @url %></p>

    <p><strong>If you did not request a log-in link a moment ago, please ignore this email.</strong> Maybe someone else entered your address by mistake.</p>
    ```

  * This email uses a custom layout which we'll define in `lib/...web/templates/layout/email.html.eex`:

    ```
    <html>
      <head>
        <style>
        </style>
      </head>
      <body>
        <%= render @view_module, @view_template, assigns %>
      </body>
    </html>
    ```

  * Now in your controller, `iex`, or other code, you can build and send an email like this:

    ```rb
    MyApp.AdminEmails.unknown_heats() |> MyApp.Mailer.deliver_now()
    ```

  * In dev, you can inspect all sent emails like this:

    ```rb
    $> Bamboo.SentEmail.all()
    ```

  * In tests, asserting against what emails were sent is straightforward. See snippet `auth_controller_test.exs` (used below).


## Tests

  * Add `auth_controller_test.exs`. (see snippet)
