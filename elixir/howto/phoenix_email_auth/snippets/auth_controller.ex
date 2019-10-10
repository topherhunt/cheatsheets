defmodule WorldviewsWeb.AuthController do
  require Logger
  use WorldviewsWeb, :controller
  alias Worldviews.Data

  # Login form
  def new(conn, _params) do
    render conn, "new.html"
  end

  # Login form submission
  def create(conn, %{"user" => %{"email" => email}}) do
    # We don't look up the user, we simply send a confirmation link to that address.
    # We'll find or create them after we confirm that they control this address.
    Worldviews.Emails.confirm_address(email) |> Worldviews.Mailer.deliver_now()
    msg = "Thanks! We just emailed you a login link. Please check your inbox (#{email})."

    conn
    |> put_flash(:info, msg)
    |> redirect(to: Routes.auth_path(conn, :new))
  end

  # The emailed login link directs here
  def confirm(conn, %{"token" => token}) do
    # This page must only redirect, not render an html response, for security reasons.
    case Data.verify_login_token(token) do
      {:ok, email} ->
        email = String.downcase(email)
        user = find_user(email) || register_user(email)
        conn
        |> WorldviewsWeb.AuthPlugs.login!(user)
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: Routes.group_path(conn, :index))

      _ ->
        conn
        |> put_flash(:error, "Hmm, that login link is too old. Please try again.")
        |> redirect(to: Routes.auth_path(conn, :new))
    end
  end

  def log_out(conn, _params) do
    if conn.assigns.current_user do
      Data.reset_user_sessions(conn.assigns.current_user)
    end

    conn
    |> WorldviewsWeb.AuthPlugs.logout!()
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
end
