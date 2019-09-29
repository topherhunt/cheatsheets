defmodule WorldviewsWeb.AuthController do
  use WorldviewsWeb, :controller
  alias Worldviews.Data

  def new(conn, _params) do
    render conn, "new.html"
  end

  # For security, this endpoint should NOT look up the user by email. It simply sends
  # a confirmation link to that address; we'll log them in once ownership is confirmed.
  def create(conn, %{"user" => %{"email" => email}}) do
    Worldviews.UserEmails.confirm_address(email) |> Worldviews.Mailer.deliver_now()
    msg = "Thanks! We just emailed you a login link. Please check your inbox (#{email})."

    conn
    |> put_flash(:info, msg)
    |> redirect(to: Routes.login_path(conn, :new))
  end

  def confirm(conn, %{"token" => token}) do
    case Data.verify_login_token(token) do
      {:ok, email} ->
        user = Data.get_user_by(email: email) || Data.insert_user!(email: email)
        conn
        |> WorldviewsWeb.AuthPlugs.login!(user)
        |> redirect(to: Routes.group_path(conn, :index)

      _ ->
        conn
        |> put_flash(:error, "Hmm, that login link is too old. Please try again.")
        |> redirect(to: Routes.auth_path(conn, :new))
    end
  end

  def logout(conn, _params) do
    user = Data.update_user!(session_token: "")
    if length(user.session_token) < 8, do: raise "User session_token wasn't repopulated!"

    conn
    |> WorldviewsWeb.AuthPlugs.logout!()
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
