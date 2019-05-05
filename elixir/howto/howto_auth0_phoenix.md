# How to set up Auth0 integration in Elixir/Phoenix

See also `howto_auth0_rails.md` which this guide is based on.


## Configuring the Auth0 account

- Sign up on Auth0, create a tenant (ie. namespace), and create an application. For app type, select "Regular web app (with page refresh)".

- Referring to the Auth0 application's settings page, set three env vars in the Rails app: `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, and `AUTH0_CLIENT_SECRET`

- In the Auth0 app settings page, add the "Allowed callback URLs" (valid redirects after login), e.g. `http://localhost:4000/auth/login_callback`. Also set the "Allowed logout URLs" (valid redirects after logout), e.g. `http://localhost:4000/`.

- In the Auth0 dashboard, under Connections, enable the Database "Username-Password-Authentication" connection. Enable "Requires username".

- In the Auth0 dashboard, under Connections, enable the Social connections for Google and Facebook. For each, make sure you enable the email scope (if email address is needed by the app). For each provider, you'll need to create a developer app integration then fill in the "Client ID" and "Client Secret". See the link, "How to obtain a client ID".


## The code

See also:

- The Auth0 official guide which gets you 80% of the way: https://auth0.com/blog/elixir-and-phoenix-tutorial-build-an-authenticated-app/
- Github readme's for ueberauth and ueberauth_auth0


### Config

Add the new packages to `mix.exs`:

```ruby
    {:ueberauth, "~> 0.6"},
    {:ueberauth_auth0, "~> 0.3"},
```

In `config.exs`, configure Ueberauth's provider and strategy:

```ruby
    config :ueberauth, Ueberauth,
      providers: [
        auth0: {
          Ueberauth.Strategy.Auth0,
          [
            request_path: "/auth/login",
            callback_path: "/auth/login_callback"
          ]
        }
      ]

    config :ueberauth, Ueberauth.Strategy.Auth0.OAuth, # <- Note the submodule!
      domain: H.env!("AUTH0_DOMAIN"),
      client_id: H.env!("AUTH0_CLIENT_ID"),
      client_secret: H.env!("AUTH0_CLIENT_SECRET")
```


### Routes, controllers

In `router.ex`, add routes for login, login_callback, logout, and force_login (optional):

```ruby
    scope "/auth" do
      # The Ueberauth login route redirects to Auth0's login page
      get "/login", AuthController, :login
      # Auth0 redirects back here after successful auth
      get "/login_callback", AuthController, :login_callback
      get "/logout", AuthController, :logout
      get "/force_login/:id", AuthController, :force_login
    end
```


Add `AuthController` with actions for login, login_callback, logout, and force_login (optional):

(TODO: Update the RTL AuthController to match this pattern more closely, so I can just tell people to copy that)

```ruby
    defmodule RTLWeb.AuthController do
      use RTLWeb, :controller
      alias RTL.Accounts
      alias RTL.Helpers, as: H
      alias RTLWeb.SessionPlugs
      require Logger

      # I think these are unnecessary
      # alias RTLWeb.Router.Helpers
      # alias Ueberauth.Strategy.Helpers

      # The Ueberauth plug magically does the following:
      # - creates a "login" action (/auth/login) that redirects to Auth0's login page
      # - after successful auth & redirect, converts Auth0's token into auth data
      #   and puts it in conn.assigns.ueberauth_*
      plug Ueberauth

      # After successful Auth0 login, the user is redirected here
      def login_callback(conn, _params) do
        if conn.assigns[:ueberauth_failure] do
          handle_auth_failure(conn)
        else
          handle_auth_success(conn)
        end
      end

      def force_login(conn, %{"id" => id, "admin_pw" => admin_pw}) do
        ensure_valid_admin_pw(admin_pw)
        user = Accounts.get_user!(id)
        Logger.warn("#force_login called; logging in as user #{user.id}.")

        conn
        |> SessionPlugs.login!(user)
        |> put_flash(:info, "Welcome back, #{user.name}!")
        |> redirect(to: "/")
      end

      def logout(conn, _params) do
        conn
        |> SessionPlugs.logout!()
        |> redirect(external: auth0_logout_url(conn))
      end

      #
      # Internal
      #

      defp handle_auth_success(conn) do
        auth = conn.assigns.ueberauth_auth
        user = Accounts.Services.FindOrCreateUserFromAuth.call(auth)

        conn
        |> SessionPlugs.login!(user)
        |> put_flash(:info, "Welcome back, #{user.name}!")
        |> redirect(to: "/")
      end

      defp handle_auth_failure(conn) do
        # I haven't yet seen a scenario where this is invoked, so I'll be lazy about it
        raise("login_callback received failure response: #{inspect(conn.assigns)}")
      end

      defp auth0_logout_url(conn) do
        domain = H.env!("AUTH0_DOMAIN")
        client_id = H.env!("AUTH0_CLIENT_ID")
        return_to = Routes.home_url(conn, :index)
        encoded_query = URI.encode_query(client_id: client_id, returnTo: return_to)
        "https://#{domain}/v2/logout?#{encoded_query}"
      end

      defp ensure_valid_admin_pw(admin_pw) do
        unless password == H.env!("FORCE_LOGIN_PASSWORD") do
          raise "force_login called with invalid password!"
        end
      end
    end
```


### Plugs

  * Copy RTL's `lib/rtl_web/plugs/session_plugs.ex` which contains plugs & helpers for login, logout, and loading current user.
  * Copy RTL's `lib/rtl_web/plugs/sentry_plugs.ex` which contains plugs & helpers for authorizing whether you're allowed to visit the current route.

In `router.ex`, update the browser pipeline to load the current user:

```ruby
    import RTLWeb.SessionPlugs, only: [load_current_user: 2] # <-- ADD THIS

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_flash
      plug :protect_from_forgery
      plug :put_secure_browser_headers
      plug :load_current_user # <-- ADD THIS
    end
```


### Finding & mapping users

Create a User schema and table (or adapt them as necessary).

The migration:

```ruby
    def change do
      create table(:users) do
        add :name, :string
        add :email, :string
        add :auth0_uid, :string
        add :last_signed_in_at, :naive_datetime
        timestamps()
      end

      create unique_index(:users, [:email])
      create unique_index(:users, [:auth0_uid])
    end
```

The schema:

```ruby
    defmodule RTL.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset
      import Ecto.Query

      schema "users" do
        field :name, :string
        field :email, :string
        field :auth0_uid, :string
        field :last_signed_in_at, :naive_datetime
        timestamps()
      end

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:name, :email, :auth0_uid, :last_signed_in_at])
        |> validate_required([:name, :email])
        |> unique_constraint(:email)
        |> unique_constraint(:auth0_uid)
      end
    end
```

Then make sure to `mix ecto.migrate` as needed.

Copy RTL's `lib/rtl/accounts/services/find_or_create_user_from_auth.ex`, which takes Oauth auth data and returns a (new or existing) User record.


### Links

Add login & logout links in the navbar. In a Bootstrap nav, it might look like this:

```html
    <%= if @current_user do %>
      <li class="nav-item dropdown">
        <a class="nav-link dropdown-toggle" href="#" data-toggle="dropdown">
          <i class="icon">settings</i> <span class="caret"></span>
        </a>
        <div class="dropdown-menu dropdown-menu-right">
          <div class="dropdown-item em small">Logged in as <%= @current_user.email %></div>
          <%= link "Log out", to: Routes.auth_path(@conn, :logout), class: "dropdown-item text-danger" %>
        </div>
      </li>
    <% else %>
      <li class="nav-item"><%= link "Log in", to: Routes.auth_path(@conn, :login), class: "nav-link" %></li>
    <% end %>
```


### Tests

  * Copy RTL's `session_plugs_test.ex`.
  * Copy RTL's `sentry_plugs_test.ex` (as relevant).

Write AuthControllerTest:

```ruby
    defmodule EyeTestWeb.AuthControllerTest do
      use EyeTestWeb.ConnCase, async: true
      alias EyeTest.Data.User

      defp force_login_path(conn, user) do
        Routes.auth_path(conn, :force_login, user.id, admin_pw: "password")
      end

      test "#force_login logs me in if id matches", %{conn: conn} do
        user = Factory.insert_user()
        conn = get(conn, force_login_path(conn, user))
        assert redirected_to(conn) == Routes.home_path(conn, :index)
        assert_logged_in(conn, user)
      end

      test "#force_login raises 404 if id doesn't match", %{conn: conn} do
        _user = Factory.insert_user()

        assert_error_sent(404, fn ->
          get(conn, force_login_path(conn, %User{id: 999}))
        end)

        assert_not_logged_in(conn)
      end

      test "#delete logs me out", %{conn: conn} do
        user = Factory.insert_user(email: "a@b.c")
        conn = get(conn, force_login_path(conn, user))
        assert_logged_in(conn, user)
        conn = get(conn, Routes.auth_path(conn, :logout))
        assert_not_logged_in(conn)
      end

      # Helpers

      defp assert_logged_in(conn, user) do
        # make another request
        conn = get(conn, "/")
        assert get_session(conn, :user_id) == user.id
      end

      defp assert_not_logged_in(conn) do
        # make another request
        conn = get(conn, "/")
        assert get_session(conn, :user_id) == nil
      end
    end
```
