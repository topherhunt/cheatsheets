defmodule JwtWeb.Api.UserControllerTest do
  use JwtWeb.ConnCase
  alias Jwt.Accounts

  describe "#me" do
    test "displays the authed user's details", %{conn: conn} do
      user = Factory.insert_user()
      token = Accounts.new_token_for_user(user)

      conn = put_req_header(conn, "authorization", "Bearer "<>token)
      conn = get(conn, Routes.api_user_path(conn, :me))

      json = json_response(conn, 200)
      assert json["email"] == user.email
    end

    test "returns 401 if token is invalid", %{conn: conn} do
      user = Factory.insert_user()
      token = Accounts.new_token_for_user(user)

      conn = put_req_header(conn, "authorization", "Bearer "<>token<>"z")
      conn = get(conn, Routes.api_user_path(conn, :me))

      assert json_response(conn, 401) == %{"error" => "invalid_token"}
    end

    test "returns 401 if no user is authed", %{conn: conn} do
      _user = Factory.insert_user()

      conn = get(conn, Routes.api_user_path(conn, :me))

      assert json_response(conn, 401) == %{"error" => "user_required"}
    end
  end
end
