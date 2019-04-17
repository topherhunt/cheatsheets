# How to set up Auth0 integration in Elixir/Phoenix

See also `howto_auth0_rails.md` which this guide is based on.


## Configuring the Auth0 account

- Sign up on Auth0, create a namespace ("tenant"), and create an application. For app type, select "Regular web app (with page refresh)".

- Referring to the Auth0 application's settings page, set three env vars in the Rails app: `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, and `AUTH0_CLIENT_SECRET`

- In the Auth0 app settings page, add the "Allowed callback URLs" (valid redirects after login), e.g. `http://localhost:3000/auth/auth0_callback`. Also set the "Allowed logout URLs" (valid redirects after logout), e.g. `http://localhost:3000/`.

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
    config :ueberauth, Ueberauth, providers: [auth0: {Ueberauth.Strategy.Auth0, []}]

    config :ueberauth, Ueberauth.Strategy.Auth0.OAuth, # <- Note the submodule!
      domain: Helpers.env("AUTH0_DOMAIN"),
      client_id: Helpers.env("AUTH0_CLIENT_ID"),
      client_secret: Helpers.env("AUTH0_CLIENT_SECRET")
```


### Routes, controllers

In `router.ex`, add routes for login, auth0_callback, logout, and force_login (optional):

```ruby
    # The Ueberauth login route redirects to Auth0's login page
    get "/auth/login", AuthController, :login
    # Auth0 redirects back here after successful auth
    get "/auth/auth0_callback", AuthController, :auth0_callback
    get "/auth/logout", AuthController, :logout
    get "/auth/login_from_uuid/:uuid", AuthController, :login_from_uuid
```


Add `AuthController` with actions for login, auth0_callback, logout, and force_login (optional):

```ruby
    defmodule RTLWeb.AuthController do
      use RTLWeb, :controller
      alias RTL.Accounts
      alias RTLWeb.SessionPlugs
      alias RTL.Helpers, as: H
      alias RTLWeb.Router.Helpers
      alias Ueberauth.Strategy.Helpers

      require Logger

      # The Ueberauth plug magically does the following:
      # - creates a "login" action (/auth/login) that redirects to Auth0's login page
      # - converts Auth0's token into auth data and puts it in conn.assigns.ueberauth_*
      plug Ueberauth

      # After successful Auth0 login, the user is redirected here
      def auth0_callback(conn, _params) do
        if conn.assigns[:ueberauth_failure] do
          handle_auth_failure(conn)
        else
          handle_auth_success(conn)
        end
      end

      def login_from_uuid(conn, %{"uuid" => uuid}) do
        user = Accounts.get_user_by!(uuid: uuid)
        Logger.warn("#login_from_uuid called; logging in as user #{user.id}.")

        conn
        |> SessionPlugs.login!(user)
        |> put_flash(:info, "Welcome back, #{user.full_name}!")
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
        |> put_flash(:info, "Welcome back, #{user.full_name}!")
        |> redirect(to: "/")
      end

      defp handle_auth_failure(conn) do
        # I haven't yet seen a scenario where this is invoked, so I'll be lazy about it
        raise("auth0_callback received failure response: #{inspect(conn.assigns)}")
      end

      defp auth0_logout_url(conn) do
        domain = H.env!("AUTH0_DOMAIN")
        client_id = H.env!("AUTH0_CLIENT_ID")
        return_to = Routes.home_url(conn, :index)
        encoded_query = URI.encode_query(client_id: client_id, returnTo: return_to)
        "https://#{domain}/v2/logout?#{encoded_query}"
      end
    end
```


### Plugs

Write `SessionPlugs` which contains helpers for loading the current user from session, requiring login, etc.:
(this is used by AuthController to log the user in & out, and also in the Router browser pipeline to load the current user)

```ruby
    defmodule RTLWeb.SessionPlugs do
      import Plug.Conn,
        only: [
          assign: 3,
          halt: 1,
          get_session: 2,
          put_session: 3,
          configure_session: 2
        ]

      import Phoenix.Controller, only: [put_flash: 3, redirect: 2]
      alias RTL.Accounts

      #
      # Plugs
      #

      # Assign current_user to the conn, if a user is logged in
      def load_current_user(conn, _opts) do
        cond do
          # If a user is already loaded, nothing to do
          current_user_assigned?(conn) -> conn
          # If no user is logged in, explicitly set current_user to nil
          no_login_session?(conn) -> assign(conn, :current_user, nil)
          # If the session is expired, log me out (must be before load_user_from_session!)
          session_expired?(conn) -> logout!(conn)
          # If we can find the user with this id, assign them
          user = load_user_from_session(conn) -> set_assigned_user(conn, user)
          # If no user was found by that id, the session is invalid. Log me out.
          true -> logout!(conn)
        end
      end

      # Deny access to this page unless a user is logged in
      def must_be_logged_in(conn, _opts) do
        if current_user_assigned?(conn) do
          conn
        else
          conn
          |> put_flash(:error, "You must be logged in to access that page.")
          |> redirect(to: RTLWeb.Router.Helpers.home_path(conn, :index))
          |> halt()
        end
      end

      def must_not_be_logged_in(conn, _opts) do
        if current_user_assigned?(conn) do
          conn
          |> put_flash(:error, "You are already logged in.")
          |> redirect(to: RTLWeb.Router.Helpers.home_path(conn, :index))
          |> halt()
        else
          conn
        end
      end

      #
      # External helpers
      #

      # Start a logged-in session for an (already authenticated) user
      def login!(conn, user) do
        Accounts.update_user!(user, %{last_signed_in_at: Timex.now()})

        conn
        |> assign(:current_user, user)
        |> put_session(:user_id, user.id)
        |> put_session(:expires_at, new_expiration_datetime_string())
        |> configure_session(renew: true)
      end

      # To log out, we just nuke the whole (cookie-stored) session.
      def logout!(conn) do
        conn
        |> assign(:current_user, nil)
        |> put_session(:user_id, nil)
        |> configure_session(drop: true)
        # But we don't halt the conn. Later plugs can decide what response to give.
      end

      #
      # Internal helpers
      #

      defp current_user_assigned?(conn) do
        conn.assigns[:current_user] != nil
      end

      defp no_login_session?(conn) do
        get_session(conn, :user_id) == nil
      end

      defp session_expired?(conn) do
        expires_at = get_session(conn, :expires_at)
        expires_at == nil || is_past?(parse_time(expires_at))
      end

      defp is_past?(time), do: Timex.before?(time, Timex.now())

      defp parse_time(string), do: Timex.parse!(string, "{ISO:Extended}")

      defp load_user_from_session(conn) do
        Accounts.get_user_by(id: get_session(conn, :user_id))
      end

      defp set_assigned_user(conn, user) do
        conn
        # Renew the session's lifetime
        |> put_session(:expires_at, new_expiration_datetime_string())
        |> assign(:current_user, user)
      end

      defp new_expiration_datetime_string do
        Timex.now() |> Timex.shift(days: +30) |> Timex.format!("{ISO:Extended}")
      end
    end
```

In `router.ex`, update the browser pipeline to load the current user:

```ruby
    # vvv new
    import RTLWeb.SessionPlugs, only: [load_current_user: 2, must_be_logged_in: 2]

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :fetch_flash
      plug :protect_from_forgery
      plug :put_secure_browser_headers
      # vvv new
      plug :load_current_user
    end
```


### Finding & mapping users

Write Accounts.Services.FindOrCreateUserFromAuth which connects the Oauth uid to a (new or existing) User record:

```ruby
    defmodule RTL.Accounts.Services.FindOrCreateUserFromAuth do
      alias RTL.Accounts
      require Logger

      def call(auth) do
        uid = auth.uid || blowup(auth, "UID is required")
        name = get_name(auth) || blowup(auth, "name is required")
        email = auth.info.email || blowup(auth, "email is required")

        cond do
          user = Accounts.get_user_by(auth0_uid: uid) ->
            Logger.info "Auth: Logged in existing user #{user.id} (#{user.email}) by auth0_uid #{uid}."
            user

          user = Accounts.get_user_by(email: email) ->
            ensure_user_doesnt_have_auth0_uid(user, auth)
            user = Accounts.update_user!(user, %{auth0_uid: uid})
            Logger.info "Auth: Mapped existing user #{user.id} (#{user.email}) to auth0_uid #{uid}."
            user

          # No user was found, we'll have to create one.
          true ->
            user = Accounts.insert_user!(%{
              auth0_uid: uid,
              full_name: name,
              email: email
            })
            Logger.info "Auth: Created new user #{user.id} (#{user.email}) for auth0_uid #{uid}."
            user
        end
      end

      defp get_name(auth) do
        # Different providers use auth.info.name differently:
        # - Auth0 db connection puts the email address there
        # - Google puts your full name there
        if String.contains?(auth.info.name, "@") do
          auth.info.nickname
        else
          auth.info.name
        end
      end

      # Just a sanity check
      defp ensure_user_doesnt_have_auth0_uid(user, auth) do
        if user.auth0_uid != nil do
          blowup(auth, "User #{user.id} matched by email, but already has an auth0_uid")
        end
      end

      defp blowup(auth, message) do
        raise "Invalid auth data: #{message}. The full auth data: #{inspect(auth)}"
      end
    end
```

And ensure the User schema knows about the required fields (name, email, auth0_uid, last_signed_in_at).
An example schema:

```ruby
    defmodule RTL.Accounts.User do
      use Ecto.Schema
      import Ecto.Changeset

      schema "users" do
        field :full_name, :string
        field :email, :string
        field :auth0_uid, :string
        field :last_signed_in_at, Timex.Ecto.DateTime
        timestamps()
      end

      def changeset(struct, params \\ %{}) do
        struct
        |> cast(params, [:full_name, :email, :auth0_uid, :last_signed_in_at])
        |> validate_required([:full_name, :email])
        |> unique_constraint(:email)
        |> unique_constraint(:auth0_uid)
      end
    end
```


### Links

Add login & logout links to the navbar:

```haml
    -# (this assumes the load_current_user plug was called)
    - if @current_user do
      = link "Log out", to: Routes.auth_path(@conn, :logout)
    - else
      = link "Log in", to: Routes.auth_path(@conn, :login)
```


### Tests

SessionPlugsTest:

```ruby
    defmodule RTLWeb.SessionPlugsTest do
      use RTLWeb.ConnCase, async: true
      alias RTLWeb.SessionPlugs
      alias RTL.Accounts

      defp put_session_expiration(conn, adjustment) do
        expiry = Timex.now() |> Timex.shift(adjustment) |> Timex.format!("{ISO:Extended}")
        put_session(conn, :expires_at, expiry)
      end

      defp assert_logged_out(conn) do
        assert get_session(conn, :user_id) == nil
        assert conn.assigns.current_user == nil
        assert conn.private.plug_session_info == :drop
        # NOTE: Logging out does NOT halt conn.
      end

      setup %{conn: conn} do
        # Sets up standard connection status (flash, session, etc.)
        conn = conn |> bypass_through(RTLWeb.Router, :browser) |> get("/")
        {:ok, %{conn: conn}}
      end

      describe "#load_current_user" do
        test "does nothing if current_user is already assigned", %{conn: conn} do
          conn = assign(conn, :current_user, "blah")
          unchanged_conn = conn
          assert SessionPlugs.load_current_user(conn, nil) == unchanged_conn
        end

        test "does nothing if there's no login session", %{conn: conn} do
          conn = SessionPlugs.load_current_user(conn, nil)
          assert get_session(conn, :user_id) == nil
          assert conn.assigns.current_user == nil
          assert !conn.halted
        end

        test "ends the session if expired", %{conn: conn} do
          conn = put_session(conn, :user_id, "123")
          conn = put_session_expiration(conn, hours: -1)
          conn = SessionPlugs.load_current_user(conn, nil)
          assert_logged_out(conn)
        end

        test "assigns current_user based on user_id", %{conn: conn} do
          user = Factory.insert_user()
          conn = put_session(conn, :user_id, user.id)
          conn = put_session_expiration(conn, hours: +1)
          conn = SessionPlugs.load_current_user(conn, nil)
          assert conn.assigns.current_user.id == user.id
        end

        test "logs me out if user_id is invalid", %{conn: conn} do
          user = Factory.insert_user()
          conn = put_session(conn, :user_id, user.id + 999)
          conn = put_session_expiration(conn, hours: +1)
          conn = SessionPlugs.load_current_user(conn, nil)
          assert_logged_out(conn)
        end
      end

      describe "#must_be_logged_in" do
        test "does nothing if current_user exists", %{conn: conn} do
          conn = assign(conn, :current_user, "something truthy")
          conn = SessionPlugs.must_be_logged_in(conn, [])
          refute conn.halted
        end

        test "redirects and halts if no current_user", %{conn: conn} do
          conn = SessionPlugs.must_be_logged_in(conn, [])
          assert redirected_to(conn) == Routes.home_path(conn, :index)
          assert conn.halted
        end
      end

      describe "#login!" do
        test "logs in this user", %{conn: conn} do
          user = Factory.insert_user()
          assert user.last_signed_in_at == nil
          assert conn.assigns[:current_user] == nil
          conn = SessionPlugs.login!(conn, user)
          assert conn.assigns.current_user.id == user.id
          assert get_session(conn, :user_id) == user.id
          reloaded_user = Accounts.get_user!(user.id)
          assert reloaded_user.last_signed_in_at != nil
        end
      end

      describe "#logout!" do
        test "drops the whole session", %{conn: conn} do
          user = Factory.insert_user()
          conn = SessionPlugs.login!(conn, user)
          assert get_session(conn, :user_id) == user.id
          conn = SessionPlugs.logout!(conn)
          assert_logged_out(conn)
        end
      end
    end
```

AuthControllerTest (just cursory coverage):

```ruby
    defmodule RTLWeb.AuthControllerTest do
      use RTLWeb.ConnCase, async: true

      test "#login_from_uuid logs me in if uuid matches", %{conn: conn} do
        user = Factory.insert_user()
        conn = get(conn, Routes.auth_path(conn, :login_from_uuid, user.uuid))
        assert redirected_to(conn) == Routes.home_path(conn, :index)
        assert_logged_in(conn, user)
      end

      test "#login_from_uuid raises 404 if uuid doesn't match", %{conn: conn} do
        user = Factory.insert_user()

        assert_error_sent(404, fn ->
          get(conn, Routes.auth_path(conn, :login_from_uuid, user.uuid <> "9"))
        end)

        assert_not_logged_in(conn)
      end

      test "#delete logs me out", %{conn: conn} do
        user = Factory.insert_user(email: "a@b.c")
        conn = get(conn, Routes.auth_path(conn, :login_from_uuid, user.uuid))
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



