defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  alias MyApp.Data

  plug :must_be_logged_in

  def edit(conn, _params) do
    changeset = Data.user_changeset(conn.assigns.current_user, :owner)
    render(conn, "edit.html", changeset: changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.current_user

    case Data.update_user(user, user_params, :owner) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, gettext("Your changes were saved."))
        |> redirect(to: Routes.user_path(conn, :edit))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def update_email(conn, %{"user" => %{"email" => email}}) do
    if Data.count_users(email: email) == 0 do
      user = conn.assigns.current_user
      MyApp.Emails.confirm_address(user, email) |> MyApp.Mailer.send()

      conn
      |> put_flash(:info, gettext("We just sent a confirmation link to %{email}. Please check your inbox.", email: email))
      |> redirect(to: Routes.user_path(conn, :edit))
    else
      conn
      |> put_flash(:error, gettext("The email address %{email} is already taken. Please try again.", email: email))
      |> redirect(to: Routes.user_path(conn, :edit))
    end
  end
end
