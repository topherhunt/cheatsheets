defmodule MyAppWeb.AuthControllerTest do
  use MyAppWeb.ConnCase, async: true
  alias MyApp.Data.User

  defp force_login_path(conn, user) do
    Routes.auth_path(conn, :force_login, user.id, admin_pw: "password")
  end

  test "#force_login logs me in if id matches", %{conn: conn} do
    user = Factory.insert_user()
    conn = get(conn, force_login_path(conn, user))
    assert redirected_to(conn) == Routes.home_path(conn, :index)
    assert_logged_in(conn, user)
  end

  test "#force_login raises 404 if id doesn't match", %{conn: conn} do
    _user = Factory.insert_user()

    assert_error_sent(404, fn ->
      get(conn, force_login_path(conn, %User{id: 999}))
    end)

    assert_not_logged_in(conn)
  end

  test "#delete logs me out", %{conn: conn} do
    user = Factory.insert_user(email: "a@b.c")
    conn = get(conn, force_login_path(conn, user))
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
