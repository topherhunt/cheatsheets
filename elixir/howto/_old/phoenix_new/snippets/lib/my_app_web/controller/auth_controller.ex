defmodule MyAppWeb.AuthController do
  require Logger
  use MyAppWeb, :controller
  alias MyApp.Data
  alias MyApp.Data.User
  alias MyAppWeb.AuthPlugs

  def signup(conn, _params) do
    changeset = Data.user_changeset(%User{}, :owner)
    render conn, "signup.html", changeset: changeset, page_title: gettext("Sign up")
  end

  def signup_submit(conn, %{"user" => user_params}) do
    case Data.insert_user(user_params, :owner) do
      {:ok, user} ->
        Logger.info "#{__MODULE__}: Registered new user #{user.id}."
        MyApp.Emails.confirm_address(user, user.email) |> MyApp.Mailer.send()

        conn
        |> put_flash(:info, gettext("Thanks for registering! Please check your inbox for a confirmation link."))
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, changeset} ->
        render conn, "signup.html", changeset: changeset, page_title: gettext("Sign up")
    end
  end

  def login(conn, _params) do
    render conn, "login.html", page_title: gettext("Log in")
  end

  def login_submit(conn, %{"user" => %{"email" => email, "password" => password}}) do
    user = Data.get_user_by(email: email) # may be nil
    pw_correct = Data.password_correct?(user, password)
    confirmed = user && user.confirmed_at != nil
    account_locked = Data.count_recent_login_tries(email) >= 5

    cond do
      account_locked ->
        conn
        |> put_flash(:error, gettext("Your account is locked. Please try again in 15 minutes, or reset your password using the link below."))
        |> redirect(to: Routes.auth_path(conn, :login))

      !pw_correct ->
        Data.insert_login_try!(email)
        conn
        |> put_flash(:error, gettext("That email or password is incorrect. Please try again."))
        |> redirect(to: Routes.auth_path(conn, :login))

      !confirmed ->
        conn
        |> put_flash(:error, gettext("You need to confirm your email address before you can log in. Please check your inbox, or use this page to request a new confirmation link."))
        |> redirect(to: Routes.auth_path(conn, :request_email_confirm))

      true ->
        Logger.info "#{__MODULE__}: Logged in user #{user.id}."
        Data.clear_login_tries(email)
        conn
        |> MyAppWeb.AuthPlugs.login!(user)
        |> put_flash(:info, gettext("Welcome back!"))
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def logout(conn, _params) do
    conn
    |> MyAppWeb.AuthPlugs.logout!()
    |> redirect(to: Routes.page_path(conn, :index))
  end

  #
  # Email confirmation
  #

  def request_email_confirm(conn, _params) do
    title = gettext("Confirm your email address")
    render conn, "request_email_confirm.html", page_title: title
  end

  def request_email_confirm_submit(conn, %{"user" => %{"email" => email}}) do
    if user = Data.get_user_by(email: email) do
      MyApp.Emails.confirm_address(user, user.email) |> MyApp.Mailer.send()
    end

    conn
    |> put_flash(:info, gettext("If that email address exists in our system, we just sent a confirmation link. Please check your inbox."))
    |> redirect(to: Routes.auth_path(conn, :request_email_confirm))
  end

  # This endpoint can be called either to confirm the user's current email, or to change
  # to a new (and newly confirmed) email.
  def confirm_email(conn, %{"token" => token}) do
    case Data.parse_token(token) do
      {:ok, {:confirm_email, user_id, email}} ->
        user = Data.get_user!(user_id)
        attrs = %{email: email, confirmed_at: DateTime.utc_now()}
        # This can fail in a rare edge case when switching to a just-taken email address.
        Data.update_user!(user, attrs, :admin)
        Data.invalidate_token!(token)

        conn
        |> AuthPlugs.login!(user)
        |> put_flash(:info, gettext("Thanks! Your email address is confirmed."))
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, _} ->
        conn
        |> put_flash(:error, gettext("That link is no longer valid. Please try again."))
        |> redirect(to: Routes.auth_path(conn, :request_email_confirm))
    end
  end

  #
  # Password resets
  #

  def request_password_reset(conn, _params) do
    title = gettext("Reset your password")
    render conn, "request_password_reset.html", page_title: title
  end

  def request_password_reset_submit(conn, %{"user" => %{"email" => email}}) do
    if user = Data.get_user_by(email: email) do
      MyApp.Emails.reset_password(user) |> MyApp.Mailer.send()
    end

    conn
    |> put_flash(:info, gettext("If that email address exists in our system, we just sent a password reset link. Please check your inbox."))
    |> redirect(to: Routes.auth_path(conn, :request_password_reset))
  end

  def reset_password(conn, %{"token" => token}) do
    case Data.parse_token(token) do
      {:ok, _} ->
        # If the pw reset token is valid, we render the form for the user to set a new pw.
        changeset = Data.user_changeset(%User{}, :owner)
        title = gettext("Reset your password")
        render conn, "reset_password.html", token: token, changeset: changeset, page_title: title

      {:error, _} ->
        conn
        |> put_flash(:error, gettext("That link is no longer valid. Please try again."))
        |> redirect(to: Routes.auth_path(conn, :request_password_reset))
    end
  end

  def reset_password_submit(conn, %{"token" => token, "user" => user_params}) do
    case Data.parse_token(token) do
      {:ok, {:reset_password, user_id}} ->
        user = Data.get_user!(user_id)
        case Data.update_user(user, user_params, :password_reset) do
          {:ok, _} ->
            Data.clear_login_tries(user.email)
            Data.invalidate_token!(token)

            conn
            |> put_flash(:info, gettext("Password updated. Please log in."))
            |> redirect(to: Routes.auth_path(conn, :login))

          {:error, changeset} ->
            title = gettext("Reset your password")
            render conn, "reset_password.html", token: token, changeset: changeset, page_title: title
        end

      {:error, _} ->
        conn
        |> put_flash(:error, gettext("Sorry, something went wrong. Please try again."))
        |> redirect(to: Routes.auth_path(conn, :request_password_reset))
    end
  end
end
