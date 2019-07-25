# Set up token-based auth in a Phoenix API app

This is the server-side setup for a Phoenix API that issues auth tokens for consumers of the API. User registration & login is all internal, we don't use Auth0.

See also:

  * https://hexdocs.pm/phoenix/Phoenix.Token.html


## Basic setup

  * Set up a standard Phoenix skeleton first (see `phoenix_new.md`)

  * Add bcrypt to `mix.exs` for password hashing:

    ```rb
    {:bcrypt_elixir, "~> 2.0"},
    ```

  * `mix deps.get`


## User schema & context

Create the Accounts context and User schema (or if you've already created them, ensure equivalent logic is in place):

  * Ensure `repo.ex` has the standard helpers (see snippet).

  * Write the Accounts context, `lib/my_app_web/accounts/accounts.ex` (see snippet).
    This contains the generic helpers for working with User records, plus logic for authenticating a user from email + password and for signing and parsing auth tokens.

  * Write the User schema, `lib/my_app_web/accounts/user.ex` (see snippet).

  * `mix ecto.gen.migration CreateUsers`

  * Fill in the CreateUsers migration:

    ```rb
    def change do
      create table(:users) do
        add :email, :string
        add :password_hash, :string

        timestamps()
      end

      create unique_index(:users, [:email])
    end
    ```

  * `mix ecto.migrate`


## Controllers & plugs

  * Write `auth_plugs.ex` which has plugs for loading user from an auth token, and requiring a user. (see snippet)

  * In `router.ex`, create an api section with a couple auth-related endpoints, and add the `load_user_from_token` plug to the api pipeline:

    ```rb
    import MyAppWeb.AuthPlugs, only: [load_user_from_token: 2]

    # ...

    pipeline :api do
      plug :accepts, ["json"]
      plug :load_user_from_token
    end

    # ...

    scope "/api", JwtWeb, as: :api do
      pipe_through :api

      post "/login", Api.AuthController, :login
      post "/register", Api.AuthController, :register

      get "/users/me", Api.UserController, :me
    end
    ```

  * In `my_app_web.ex`, in the controller quote, import the require_user plug:

    ```rb
    import JwtWeb.AuthPlugs, only: [require_user: 2]
    ```

  * Write `lib/my_app_web/controllers/api/auth_controller.ex` (see snippet). This has actions for login (ie. getting an auth token) and registration.

  * Write `lib/my_app_web/controllers/api/user_controller.ex` (see snippet). This has one protected endpoint `/api/users/me` which lets us test out login-restricted endpoints.

Useful pattern: each api endpoint's response json should include an :ok bool flag indicating whether this request was a success. If ok == false, include a standard "reason" field explaining the problem. This gives the consumer a consistent api to verify success against.


## Tests

  * In `test.exs`, configure bcrypt to be less inefficient:

    ```rb
    # Make bcrypt less inefficient in tests
    config :bcrypt_elixir, log_rounds: 4
    ```

  * In `test/support/conn_case.ex`, in the quote block, add: `alias Jwt.Factory`

  * Write `lib/my_app/factory.ex` or add an `insert_user` helper to it (see snippet)

  * Write `test/my_app_web/controllers/api/auth_controllers_test.ex` (see snippet)

  * Write `test/my_app_web/controllers/api/user_controllers_test.ex` (see snippet)

  * Run `mix test`. Confirm that your new tests ran and passed.


## Next steps to consider

  * If relevant, set up your React/Redux client to consume this API. See `setup_react_redux.md`

  * Consider token expiration. Should tokens older than X days be rejected? If so, how do we signal to the consumer that their token will expire soon and they need to request a fresh one?
