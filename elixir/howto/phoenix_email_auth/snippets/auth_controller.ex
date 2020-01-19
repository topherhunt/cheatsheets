defmodule MyAppWeb.AuthController do
  use MyAppWeb, :controller
  alias MyApp.Data
  require Logger

  def login(conn, _params) do
    render conn, "login.html"
  end

  def login_submit(conn, %{"user" => %{"email" => email}}) do
    # We don't look up the user, we simply send a confirmation link to that address.
    # We'll find or create them after we confirm that they control this address.
    # Silently ignores sending failures.
    MyApp.Emails.confirm_address(email) |> MyApp.Mailer.send()
    msg = "Thanks! We just emailed you a login link. Please check your inbox (#{email})."

    conn
    |> put_flash(:info, msg)
    |> redirect(to: Routes.auth_path(conn, :login))
  end

  # The emailed login link directs here.
  # NOTE: This endpoint must only redirect, never render html, for security reasons.
  def confirm(conn, %{"token" => token}) do
    case Data.verify_login_token(token) do
      {:ok, email} ->
        user = find_user(email) || register_user(email)
        conn = MyAppWeb.AuthPlugs.login!(conn, user)
        redirect_after_confirm(conn, user)

      _ ->
        conn
        |> put_flash(:error, "Hmm, that login link is too old. Please try again.")
        |> redirect(to: Routes.auth_path(conn, :login))
    end
  end

  def log_out(conn, _params) do
    if conn.assigns.current_user do
      Data.reset_user_sessions(conn.assigns.current_user)
    end

    conn
    |> MyAppWeb.AuthPlugs.logout!()
    |> redirect(to: Routes.page_path(conn, :index))
  end

  #
  # Helpers
  #

  defp find_user(email) do
    if user = Data.get_user_by(email: email) do
      Logger.info "Logged in existing user #{user.id} (#{user.email})"
      user
    end
  end

  defp register_user(email) do
    user = Data.insert_user!(%{email: email})
    Logger.info "Registered new user #{user.id} (#{user.email})"
    user
  end

  defp redirect_after_confirm(conn, user) do
    cond do
      # [[[OPTIONAL]]] Direct newly registered users to fill in their account info
      user.full_name == nil ->
        conn
        |> put_flash(:info, "Please enter your name to complete registration.")
        |> redirect(to: Routes.user_path(conn, :edit))

      return_to = conn.req_cookies["return_to"] ->
        conn
        |> delete_resp_cookie("return_to")
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: return_to)

      true ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
