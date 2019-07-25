defmodule JwtWeb.Api.AuthControllerTest do
  use JwtWeb.ConnCase
  alias Jwt.Accounts

  describe "#login" do
    test "returns an auth token when your credentials are valid", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"email" => user.email, "password" => user.password}
      conn = post(conn, Routes.api_auth_path(conn, :login), params)

      %{"token" => token} = json_response(conn, 200)
      {:ok, user_id} = Accounts.verify_token_and_get_user_id(token)
      assert user_id == user.id
    end

    test "returns 401 when password is invalid", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"email" => user.email, "password" => user.password <> "x"}
      conn = post(conn, Routes.api_auth_path(conn, :login), params)

      %{"error" => "invalid_credentials"} = json_response(conn, 401)
    end

    # This is a separate code pathway, so we cover it separately
    test "returns 401 when email is invalid", %{conn: conn} do
      user = Factory.insert_user()

      params = %{"email" => user.email <> "x", "password" => user.password}
      conn = post(conn, Routes.api_auth_path(conn, :login), params)

      %{"error" => "invalid_credentials"} = json_response(conn, 401)
    end
  end

  describe "#register" do
    test "inserts the user and returns auth token when valid", %{conn: conn} do
      pre_count = Accounts.count_users()

      params = %{"user" => %{"email" => "daffy@example.com", "password" => "password1"}}
      conn = post(conn, Routes.api_auth_path(conn, :register), params)

      assert Accounts.count_users() == pre_count + 1
      %{"token" => token} = json_response(conn, 200)
      {:ok, user_id} = Accounts.verify_token_and_get_user_id(token)
      assert Accounts.get_user!(user_id).email == "daffy@example.com"
    end

    test "returns 422 if user params are invalid", %{conn: conn} do
      pre_count = Accounts.count_users()

      params = %{"user" => %{"emial" => "daffy@example.com", "password" => "password1"}}
      conn = post(conn, Routes.api_auth_path(conn, :register), params)

      assert Accounts.count_users() == pre_count
      assert json_response(conn, 422) == %{"errors" => ["email can't be blank"]}
    end
  end
end
