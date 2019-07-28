# Here's a sample UserControllerTest for an api.
# I use some custom helpers to make things more compact & readable:
# - set_auth_token
# - assert_record_fields
# - assert_records_match
#
defmodule MyAppWeb.Api.UserControllerTest do
  use MyAppWeb.ConnCase
  alias MyApp.Accounts

  describe "all actions" do
    test "fails for non-authed user", %{conn: conn} do
      user1 = Factory.insert_user()

      # No auth token
      conn = get(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 401)
      assert json["ok"] == false
      assert json["reason"] == "You must be logged in to take that action."
    end

    test "works for admin same as for manager", %{conn: conn} do
      user1 = Factory.insert_user()
      admin = Factory.insert_user(role: "admin")

      conn = set_auth_token(conn, admin)
      conn = delete(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 204)
      assert json["ok"] == true
      assert Accounts.get_user(user1.id) == nil
    end

    test "fails if scoped user_id is invalid", %{conn: conn} do
      _user1 = Factory.insert_user()
      admin = Factory.insert_user(role: "admin")
      conn = set_auth_token(conn, admin)

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, "/api/users/987654321")
      end
    end
  end

  describe "#index" do
    test "fails for normal user", %{conn: conn} do
      user1 = Factory.insert_user()
      _user2 = Factory.insert_user()
      _manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, user1)
      conn = get(conn, "/api/users")

      json = json_response(conn, 403)
      assert json["ok"] == false
      assert json["users"] == nil
    end

    test "works for manager", %{conn: conn} do
      user1 = Factory.insert_user()
      user2 = Factory.insert_user()
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      conn = get(conn, "/api/users")

      json = json_response(conn, 200)
      assert json["ok"] == true
      assert_record_fields(List.first(json["users"]), ~w(id username role inserted_at))
      assert_records_match(json["users"], [user1, user2, manager])
    end
  end

  describe "#create" do
    defp create_params(opts \\ []) do
      %{username: "abc", password: "def", role: "user", target_calories_per_day: 2000}
      |> Map.merge(Enum.into(opts, %{}))
    end

    test "fails for normal user", %{conn: conn} do
      user1 = Factory.insert_user()
      user_count = Accounts.count_users()

      conn = set_auth_token(conn, user1)
      params = %{user: create_params()}
      conn = post(conn, "/api/users", params)

      json = json_response(conn, 403)
      assert json["ok"] == false
      assert Accounts.count_users() == user_count
    end

    test "works for manager", %{conn: conn} do
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      params = %{user: create_params()}
      conn = post(conn, "/api/users", params)

      json = json_response(conn, 200)
      assert json["ok"] == true
      assert_record_fields(json["user"], ~w(id username role))
      new_user = Accounts.get_user!(json["user"]["id"])
      assert new_user.username == "abc"
      assert new_user.role == "user"
    end

    test "fails if invalid params", %{conn: conn} do
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      params = %{user: create_params(username: "")}
      conn = post(conn, "/api/users", params)

      json = json_response(conn, 422)
      assert json["ok"] == false
      assert json["reason"] =~ "username can't be blank"
    end

    test "fails if manager is trying to set escalated role", %{conn: conn} do
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      params = %{user: create_params(role: "admin")}
      conn = post(conn, "/api/users", params)

      json = json_response(conn, 403)
      assert json["ok"] == false
      assert json["reason"] =~ "You don't have permission to give users that role."
    end

    test "allows admin to set escalated role", %{conn: conn} do
      admin = Factory.insert_user(role: "admin")

      conn = set_auth_token(conn, admin)
      params = %{user: create_params(role: "admin")}
      conn = post(conn, "/api/users", params)

      json = json_response(conn, 200)
      assert json["ok"] == true
      new_user = Accounts.get_user!(json["user"]["id"])
      assert new_user.username == "abc"
      assert new_user.role == "admin"
    end
  end

  describe "#show" do
    test "fails for normal user who is not the scope", %{conn: conn} do
      user1 = Factory.insert_user()
      user2 = Factory.insert_user()

      conn = set_auth_token(conn, user2)
      conn = get(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 403)
      assert json["ok"] == false
      assert json["reason"] == "You don't have permission to take that action."
    end

    test "works for normal user who is the scope", %{conn: conn} do
      user1 = Factory.insert_user()
      _user2 = Factory.insert_user()

      conn = set_auth_token(conn, user1)
      conn = get(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 200)
      assert json["ok"] == true
      assert_record_fields(json["user"], ~w(id username role))
      assert json["user"]["id"] == user1.id
    end

    test "works for manager", %{conn: conn} do
      user1 = Factory.insert_user()
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      conn = get(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 200)
      assert json["ok"] == true
      assert_record_fields(json["user"], ~w(id username role))
      assert json["user"]["id"] == user1.id
    end
  end

  describe "#update" do
    test "fails for normal user who is not the scope", %{conn: conn} do
      user1 = Factory.insert_user(username: "orig_username")
      user2 = Factory.insert_user()

      conn = set_auth_token(conn, user2)
      params = %{user: %{username: "new_username", target_calories_per_day: 1500}}
      conn = patch(conn, "/api/users/#{user1.id}", params)

      json = json_response(conn, 403)
      assert json["reason"] =~ "You don't have permission to take that action."
      assert Accounts.get_user!(user1.id).username == "orig_username"
    end

    test "works for normal user who is the scope", %{conn: conn} do
      user1 = Factory.insert_user()

      conn = set_auth_token(conn, user1)
      params = %{user: %{username: "new_username", target_calories_per_day: 1500}}
      conn = patch(conn, "/api/users/#{user1.id}", params)

      json = json_response(conn, 200)
      assert json["ok"] == true
      updated = Accounts.get_user!(user1.id)
      assert updated.username == "new_username"
      assert updated.target_calories_per_day == 1500
    end

    test "works for manager", %{conn: conn} do
      user1 = Factory.insert_user()
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      params = %{user: %{username: "new_username", target_calories_per_day: 1500}}
      conn = patch(conn, "/api/users/#{user1.id}", params)

      json = json_response(conn, 200)
      assert json["ok"] == true
      updated = Accounts.get_user!(user1.id)
      assert updated.username == "new_username"
      assert updated.target_calories_per_day == 1500
    end

    test "fails if invalid params", %{conn: conn} do
      user1 = Factory.insert_user()
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      params = %{user: %{username: "", target_calories_per_day: 1500}}
      conn = patch(conn, "/api/users/#{user1.id}", params)

      json = json_response(conn, 422)
      assert json["reason"] == "username can't be blank"
    end
  end

  describe "#delete" do
    test "fails for normal user who is not the scope", %{conn: conn} do
      user1 = Factory.insert_user()
      user2 = Factory.insert_user()

      conn = set_auth_token(conn, user2)
      conn = delete(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 403)
      assert json["ok"] == false
      assert json["reason"] =~ "You don't have permission to take that action."
    end

    test "works for normal user who is the scope", %{conn: conn} do
      user1 = Factory.insert_user()

      conn = set_auth_token(conn, user1)
      conn = delete(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 204)
      assert json["ok"] == true
      assert Accounts.get_user(user1.id) == nil
    end

    test "works for manager", %{conn: conn} do
      user1 = Factory.insert_user()
      manager = Factory.insert_user(role: "manager")

      conn = set_auth_token(conn, manager)
      conn = delete(conn, "/api/users/#{user1.id}")

      json = json_response(conn, 204)
      assert json["ok"] == true
      assert Accounts.get_user(user1.id) == nil
    end
  end
end
