defmodule EyeTestWeb.AuthController do
  use EyeTestWeb, :controller
  alias EyeTest.Accounts
  alias EyeTest.Helpers, as: H
  alias EyeTestWeb.SessionPlugs
  require Logger

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
    unless admin_pw == H.env!("FORCE_LOGIN_PASSWORD") do
      raise "force_login called with invalid password!"
    end
  end
end
