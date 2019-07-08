defmodule MyAppWeb.SessionPlugsTest do
  use MyAppWeb.ConnCase, async: true
  alias MyAppWeb.SessionPlugs
  alias MyApp.Orgs

  defp put_session_expiration(conn, adjustment) do
    expiry = Timex.now() |> Timex.shift(adjustment) |> Timex.format!("{ISO:Extended}")
    put_session(conn, :expires_at, expiry)
  end

  defp assert_logged_out(conn) do
    assert get_session(conn, :user_id) == nil
    assert conn.assigns.current_user == nil
    assert conn.private.plug_session_info == :drop
    # NOTE: Logging out does NOT halt conn.
  end

  setup %{conn: conn} do
    # Sets up standard connection status (flash, session, etc.)
    conn = conn |> bypass_through(MyAppWeb.Router, :browser) |> get("/")
    {:ok, %{conn: conn}}
  end

  describe "#load_current_user" do
    test "does nothing if current_user is already assigned", %{conn: conn} do
      conn = assign(conn, :current_user, "blah")
      unchanged_conn = conn
      assert SessionPlugs.load_current_user(conn, nil) == unchanged_conn
    end

    test "does nothing if there's no login session", %{conn: conn} do
      conn = SessionPlugs.load_current_user(conn, nil)
      assert get_session(conn, :user_id) == nil
      assert conn.assigns.current_user == nil
      assert !conn.halted
    end

    test "ends the session if expired", %{conn: conn} do
      conn = put_session(conn, :user_id, "123")
      conn = put_session_expiration(conn, hours: -1)
      conn = SessionPlugs.load_current_user(conn, nil)
      assert_logged_out(conn)
    end

    test "assigns current_user based on user_id", %{conn: conn} do
      user = Factory.insert_user()
      conn = put_session(conn, :user_id, user.id)
      conn = put_session_expiration(conn, hours: +1)
      conn = SessionPlugs.load_current_user(conn, nil)
      assert conn.assigns.current_user.id == user.id
    end

    test "logs me out if user_id is invalid", %{conn: conn} do
      user = Factory.insert_user()
      conn = put_session(conn, :user_id, user.id + 999)
      conn = put_session_expiration(conn, hours: +1)
      conn = SessionPlugs.load_current_user(conn, nil)
      assert_logged_out(conn)
    end
  end

  describe "#must_be_logged_in" do
    test "does nothing if current_user exists", %{conn: conn} do
      conn = assign(conn, :current_user, "something truthy")
      conn = SessionPlugs.must_be_logged_in(conn, [])
      refute conn.halted
    end

    test "redirects and halts if no current_user", %{conn: conn} do
      conn = SessionPlugs.must_be_logged_in(conn, [])
      assert redirected_to(conn) == Routes.home_path(conn, :index)
      assert conn.halted
    end
  end

  describe "#login!" do
    test "logs in this user", %{conn: conn} do
      user = Factory.insert_user()
      assert user.last_signed_in_at == nil
      assert conn.assigns[:current_user] == nil
      conn = SessionPlugs.login!(conn, user)
      assert conn.assigns.current_user.id == user.id
      assert get_session(conn, :user_id) == user.id
      reloaded_user = Orgs.get_user!(user.id)
      assert reloaded_user.last_signed_in_at != nil
    end
  end

  describe "#logout!" do
    test "drops the whole session", %{conn: conn} do
      user = Factory.insert_user()
      conn = SessionPlugs.login!(conn, user)
      assert get_session(conn, :user_id) == user.id
      conn = SessionPlugs.logout!(conn)
      assert_logged_out(conn)
    end
  end
end
