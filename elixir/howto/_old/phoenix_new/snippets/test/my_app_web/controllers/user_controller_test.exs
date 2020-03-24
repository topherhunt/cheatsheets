defmodule MyAppWeb.UserControllerTest do
  use MyAppWeb.ConnCase
  alias MyApp.Data

  setup do
    # Clear all emails sent by previous tests. Tests CANNOT be async.
    Bamboo.SentEmail.reset()
  end

  describe "#edit" do
    test "renders correctly", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)

      conn = get(conn, Routes.user_path(conn, :edit))

      assert_selector conn, "h1", html: "Account settings"
    end
  end

  describe "#update" do
    test "user can update their name and password", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)

      params = %{"user" => %{"name" => "New name", "password" => "password2", "password_confirmation" => "password2", "current_password" => "password"}}
      conn = patch(conn, Routes.user_path(conn, :update), params)

      assert redirected_to(conn) == Routes.user_path(conn, :edit)
      updated_user = Data.get_user!(user.id)
      assert updated_user.name == "New name"
      assert Data.password_correct?(updated_user, "password2")
    end

    test "user can update just their name", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)

      params = %{"user" => %{"name" => "New name"}}
      conn = patch(conn, Routes.user_path(conn, :update), params)

      assert redirected_to(conn) == Routes.user_path(conn, :edit)
      assert Data.get_user!(user.id).name == "New name" # Name has changed
    end

    test "rejects if name is invalid", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)

      params = %{"user" => %{"name" => ""}}
      conn = patch(conn, Routes.user_path(conn, :update), params)

      assert_text conn, "can't be blank"
      assert Data.get_user!(user.id).name == user.name # Name hasn't changed
    end

    test "rejects if updating password and current_password is incorrect", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)

      params = %{"user" => %{"name" => "New name", "password" => "password2", "password_confirmation" => "password2", "current_password" => "wrong"}}
      conn = patch(conn, Routes.user_path(conn, :update), params)

      assert_text conn, "is incorrect"
      assert Data.get_user!(user.id) |> Data.password_correct?("password") # PW hasn't changed
    end
  end

  describe "#update_email" do
    test "sends you an email confirmation link, but doesn't update email", %{conn: conn} do
      user = Factory.insert_user()
      conn = login(conn, user)

      params = %{"user" => %{"email" => "new_email@example.com"}}
      conn = patch(conn, Routes.user_path(conn, :update_email), params)

      assert redirected_to(conn) == Routes.user_path(conn, :edit)
      assert flash_messages(conn) =~ "We just sent a confirmation link"
      assert Data.get_user!(user.id).email == user.email # email hasn't changed (yet)
      assert_email_sent(to: "new_email@example.com", subject: "Please confirm your address")
    end

    test "rejects if that email address is taken", %{conn: conn} do
      user = Factory.insert_user()
      user2 = Factory.insert_user()
      conn = login(conn, user)

      params = %{"user" => %{"email" => user2.email}}
      conn = patch(conn, Routes.user_path(conn, :update_email), params)

      assert redirected_to(conn) == Routes.user_path(conn, :edit)
      assert flash_messages(conn) =~ "The email address #{user2.email} is already taken"
    end
  end
end
