defmodule MyAppWeb.AuthControllerTest do
  use MyAppWeb.ConnCase
  alias MyApp.Data

  setup do
    # Clear all emails sent by previous tests.
    # NOT compatible with async tests.
    Bamboo.SentEmail.reset()
  end

  def ts_now, do: System.system_time(:second)
  def ts_nearly_1h_ago, do: ts_now() - 3595
  def ts_over_1h_ago, do: ts_now() - 3605

  describe "#new" do
    test "renders the login form", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :new))

      assert html_response(conn, 200) =~ "Enter your email address"
    end
  end

  describe "#create" do
    test "emails a signed login link to the provided address", %{conn: conn} do
      params = %{user: %{email: "elmer.fudd@example.com"}}
      conn = post(conn, Routes.auth_path(conn, :create), params)

      assert redirected_to(conn) == Routes.auth_path(conn, :new)

      [email] = Bamboo.SentEmail.all()
      assert email.subject =~ "Your special log-in link"
      assert email.to == [nil: "elmer.fudd@example.com"]
      assert email.html_body =~ "Please click the link below to log in."

      assert [_, token] = Regex.run(~r/\?token=([\w\d\.\-\_]+)/, email.html_body)
      assert {:ok, "elmer.fudd@example.com"} = Data.verify_login_token(token)
    end
  end

  describe "#confirm" do
    test "when valid and user exists: logs you in", %{conn: conn} do
      user = Factory.insert_user(email: "daffy@example.com")

      # User visits the confirm page with a nearly-expired link.
      token = stub_token("Daffy@EXAMPLE.com", ts_nearly_1h_ago())
      conn = get(conn, Routes.auth_path(conn, :confirm, token: token))

      assert redirected_to(conn) == Routes.group_path(conn, :index)
      assert_logged_in(conn, user)
    end

    test "when valid and user does not exist: registers & logs you in", %{conn: conn} do
      # Token contains a capitalized email, but is registered as lower-cased
      token = stub_token("Daisy@EXAMPLE.com", ts_now())
      conn = get(conn, Routes.auth_path(conn, :confirm, token: token))

      assert user = Data.get_user_by!(email: "daisy@example.com")
      assert redirected_to(conn) == Routes.group_path(conn, :index)
      assert_logged_in(conn, user)
    end

    test "when link is expired: rejects and redirects", %{conn: conn} do
      token = stub_token("Daisy@EXAMPLE.com", ts_over_1h_ago())
      conn = get(conn, Routes.auth_path(conn, :confirm, token: token))

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert_logged_out(conn)
    end

    test "when link is invalid: rejects and redirects", %{conn: conn} do
      token = stub_token("Daisy@EXAMPLE.com", ts_now())
      conn = get(conn, Routes.auth_path(conn, :confirm, token: token<>"z"))

      assert redirected_to(conn) == Routes.auth_path(conn, :new)
      assert_logged_out(conn)
    end
  end

  describe "#logout" do
    test "logs you out of all your sessions", %{conn: conn} do
      user = Factory.insert_user()
      token = stub_token(user.email, ts_now())
      conn = get(conn, Routes.auth_path(conn, :confirm, token: token))
      assert_logged_in(conn, user)

      conn = get(conn, Routes.auth_path(conn, :log_out))

      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert_logged_out(conn)

      # Login session token has been resets
      old_login_token = user.session_token
      new_login_token = Data.get_user!(user.id).session_token
      assert new_login_token != old_login_token
      assert String.length(old_login_token) >= 8
      assert String.length(new_login_token) >= 8
    end
  end

  #
  # Helpers
  #

  defp stub_token(email, signed_at) do
    endpoint = MyAppWeb.Endpoint
    Phoenix.Token.sign(endpoint, "login token salt", email, signed_at: signed_at)
  end

  defp assert_logged_in(conn, user) do
    conn = get(conn, Routes.page_path(conn, :index))
    assert conn.resp_body =~ "Log out"
    assert conn.resp_body =~ String.downcase(user.email)
    refute conn.resp_body =~ "Log in"
  end

  defp assert_logged_out(conn) do
    conn = get(conn, Routes.page_path(conn, :index))
    assert conn.resp_body =~ "Log in"
    refute conn.resp_body =~ "Log out"
  end
end
