# How to set up Auth0 integration in Elixir/Phoenix

  * Consider using a JS login flow instead. See the JS Facebook login system I implemented in a recent Rails app (commit `13fae27` on 2019-12-17).
  * See also `howto_auth0_rails.md` which this guide is based on.


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

Write `auth_controller.ex` (see snippet) which has actions for login, login_callback, logout, and force_login (optional):


### Plugs

  * Write `lib/rtl_web/plugs/session_plugs.ex` (see snippet).
  * Write `lib/rtl_web/plugs/sentry_plugs.ex` (see snippet).

In `router.ex`, update the browser pipeline to load the current user:

```ruby
  # <<< ADD THIS: >>>
  import RTLWeb.SessionPlugs, only: [load_current_user: 2]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    # <<< ADD THIS: >>>
    plug :load_current_user
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

Write `lib/my_app/some_context/services/find_or_create_user_from_auth.ex` (see snippet). This service takes Oauth auth data and returns a (new or existing) User record.


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

  * Write `session_plugs_test.ex` (see snippet).
  * Write `sentry_plugs_test.ex` if relevant (see snippet).
  * Write `auth_controller_test.ex` (see snippet).
