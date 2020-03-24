defmodule MyAppWeb.AuthControllerTest do
  use MyAppWeb.ConnCase
  alias MyApp.Data

  setup do
    # Clear all emails sent by previous tests. Tests CANNOT be async.
    Bamboo.SentEmail.reset()
  end

  describe "#signup" do
    test "renders correctly", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :signup))

      assert_selector conn, "h1", html: "Sign up"
    end
  end

  describe "#signup_submit" do
    test "registers you and emails you a confirmation link", %{conn: conn} do
      assert Data.count_users(email: "topher@example.com") == 0

      params = %{"user" => %{"name" => "Topher", "email" => "topher@example.com", "password" => "password1", "password_confirmation" => "password1"}}
      conn = post(conn, Routes.auth_path(conn, :signup_submit), params)

      assert redirected_to(conn) =~ Routes.page_path(conn, :index)
      assert Data.count_users(email: "topher@example.com") == 1
      assert_email_sent(to: "topher@example.com", subject: "Please confirm your address")
      assert_logged_out(conn) # you aren't logged in, email confirmation is required
    end

    test "rejects your submission when invalid", %{conn: conn} do
      params = %{"user" => %{"name" => "", "email" => "topher@example.com", "password" => "password1", "password_confirmation" => "password1"}}
      conn = post(conn, Routes.auth_path(conn, :signup_submit), params)

      assert_text conn, "can't be blank"
      assert Data.count_users(email: "topher@example.com") == 0
      assert count_emails_sent() == 0
    end

    test "requires password confirmation", %{conn: conn} do
      params = %{"user" => %{"name" => "Topher", "email" => "topher@example.com", "password" => "password1", "password_confirmation" => "password2"}}
      conn = post(conn, Routes.auth_path(conn, :signup_submit), params)

      assert_text conn, "doesn't match password"
      assert Data.count_users(email: "topher@example.com") == 0
      assert count_emails_sent() == 0
    end
  end

  describe "#login" do
    test "renders correctly", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :login))

      assert_selector conn, "h1", html: "Log in"
    end
  end

  describe "#login_submit" do
    test "logs you in on success", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"user" => %{"email" => user.email, "password" => "password"}}
      conn = post(conn, Routes.auth_path(conn, :login_submit), params)

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert_logged_in(conn, user)
    end

    test "rejects you when your account is locked", %{conn: conn} do
      user = Factory.insert_user()
      1..5 |> Enum.each(fn _i -> Factory.insert_login_try(email: user.email) end)

      params = %{"user" => %{"email" => user.email, "password" => "password"}}
      conn = post(conn, Routes.auth_path(conn, :login_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :login)
      assert flash_messages(conn) =~ "Your account is locked."
      assert_logged_out(conn)
    end

    test "rejects you when your UN/PW is incorrect", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"user" => %{"email" => user.email, "password" => "passwrd"}}
      conn = post(conn, Routes.auth_path(conn, :login_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :login)
      assert flash_messages(conn) =~ "That email or password is incorrect."
      assert_logged_out(conn)
    end

    test "rejects you when your account isn't yet confirmed", %{conn: conn} do
      user = Factory.insert_user(confirmed_at: nil)

      params = %{"user" => %{"email" => user.email, "password" => "password"}}
      conn = post(conn, Routes.auth_path(conn, :login_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :request_email_confirm)
      assert flash_messages(conn) =~ "You need to confirm your email address"
      assert_logged_out(conn)
    end
  end

  describe "#logout" do
    test "logs you out", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)
      assert_logged_in(conn, user)

      conn = get(conn, Routes.auth_path(conn, :logout))

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert_logged_out(conn)
    end
  end

  describe "#request_email_confirm" do
    test "renders correctly", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :request_email_confirm))

      assert_selector conn, "h1", html: "Confirm your account"
    end
  end

  describe "#request_email_confirm_submit" do
    test "sends the confirmation link if that email exists", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"user" => %{"email" => user.email}}
      conn = post(conn, Routes.auth_path(conn, :request_email_confirm_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :request_email_confirm)
      assert count_emails_sent() == 1
      assert_email_sent(to: user.email, subject: "Please confirm your address")
    end

    test "does nothing if that email doesn't exist", %{conn: conn} do
      _user = Factory.insert_user()

      params = %{"user" => %{"email" => "incorrect@example.com"}}
      conn = post(conn, Routes.auth_path(conn, :request_email_confirm_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :request_email_confirm)
      assert count_emails_sent() == 0
    end
  end

  describe "#confirm_email" do
    test "confirms your account if the token is valid", %{conn: conn} do
      user = Factory.insert_user(confirmed_at: nil)

      token = Data.create_token!({:confirm_email, user.id, user.email})
      conn = get(conn, Routes.auth_path(conn, :confirm_email), %{"token" => token})

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert flash_messages(conn) == "Thanks! Your email address is confirmed."
      assert_logged_in(conn, user)
    end

    test "rejects you if token is invalid", %{conn: conn} do
      user = Factory.insert_user(confirmed_at: nil)

      token = Data.create_token!({:confirm_email, user.id, user.email})<>"z"
      conn = get(conn, Routes.auth_path(conn, :confirm_email), %{"token" => token})

      assert redirected_to(conn) == Routes.auth_path(conn, :request_email_confirm)
      assert flash_messages(conn) =~ "That link is no longer valid."
      assert_logged_out(conn)
    end
  end

  describe "#request_password_reset" do
    test "renders correctly", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :request_password_reset))

      assert_selector conn, "h1", html: "Reset your password"
    end
  end

  describe "#request_password_reset_submit" do
    test "sends the password reset link if that email exists", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"user" => %{"email" => user.email}}
      conn = post(conn, Routes.auth_path(conn, :request_password_reset_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :request_password_reset)
      assert count_emails_sent() == 1
      assert_email_sent(to: user.email, subject: "Use this link to reset your password")
    end

    test "does nothing if that email doesn't exist", %{conn: conn} do
      _user = Factory.insert_user()

      params = %{"user" => %{"email" => "incorrect@example.com"}}
      conn = post(conn, Routes.auth_path(conn, :request_password_reset_submit), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :request_password_reset)
      assert count_emails_sent() == 0
    end
  end

  describe "#reset_password" do
    test "displays the password reset form if that token is valid", %{conn: conn} do
      user = Factory.insert_user()

      token = Data.create_token!({:reset_password, user.id})
      conn = get(conn, Routes.auth_path(conn, :reset_password), %{"token" => token})

      assert_selector conn, "h1", html: "Reset your password"
      assert_selector conn, "input#user_password_confirmation"
    end

    test "rejects you if the token is invalid", %{conn: conn} do
      user = Factory.insert_user()
      token = Data.create_token!({:reset_password, user.id})<>"z"

      conn = get(conn, Routes.auth_path(conn, :reset_password), %{"token" => token})

      assert redirected_to(conn) == Routes.auth_path(conn, :request_password_reset)
      assert flash_messages(conn) =~ "That link is no longer valid."
    end
  end

  describe "#reset_password_submit" do
    test "updates your password when token and password are valid", %{conn: conn} do
      user = Factory.insert_user()
      token = Data.create_token!({:reset_password, user.id})

      conn = post(conn, Routes.auth_path(conn, :reset_password_submit), %{
        "token" => token,
        "user" => %{"password" => "password2", "password_confirmation" => "password2"}
      })

      assert redirected_to(conn) == Routes.auth_path(conn, :login)
      assert flash_messages(conn) == "Password updated. Please log in."
      assert Data.get_user!(user.id) |> Data.password_correct?("password2")
    end

    test "rejects you if the token is invalid", %{conn: conn} do
      user = Factory.insert_user()
      token = Data.create_token!({:reset_password, user.id})<>"z"

      conn = post(conn, Routes.auth_path(conn, :reset_password_submit), %{
        "token" => token,
        "user" => %{"password" => "password2", "password_confirmation" => "password2"}
      })

      assert redirected_to(conn) == Routes.auth_path(conn, :request_password_reset)
      assert flash_messages(conn) == "Sorry, something went wrong. Please try again."
      assert !(Data.get_user!(user.id) |> Data.password_correct?("password2"))
    end

    test "rejects you if the new password is invalid", %{conn: conn} do
      user = Factory.insert_user()
      token = Data.create_token!({:reset_password, user.id})

      conn = post(conn, Routes.auth_path(conn, :reset_password_submit), %{
        "token" => token,
        "user" => %{"password" => "password2", "password_confirmation" => "password3"}
      })

      assert_text conn, "doesn't match password"
      assert !(Data.get_user!(user.id) |> Data.password_correct?("password2"))
    end
  end
end
