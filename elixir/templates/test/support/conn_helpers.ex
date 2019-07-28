# Helpers I use to make API controller tests easier to write & cleaner to read.
#
defmodule MyAppWeb.ConnHelpers do
  import ExUnit.Assertions
  import Plug.Conn
  alias MyApp.Accounts

  def set_auth_token(conn, user) do
    token = Accounts.new_token_for_user(user)
    put_req_header(conn, "authorization", "Bearer "<>token)
  end

  # Helps us assert the shape of the json response
  # e.g.: assert map_has_fields?(List.first(json["users"]), ~w(id username role))
  def assert_record_fields(map, fields) do
    Enum.each(fields, fn(field) ->
      assert Map.has_key?(map, field),
        "Map #{inspect(map)} doesn't have expected field: #{inspect(field)}"
    end)
  end

  def assert_records_match(returned_records, expected_records) do
    returned_ids = Enum.map(returned_records, & &1["id"]) |> Enum.sort
    expected_ids = Enum.map(expected_records, & &1.id) |> Enum.sort
    assert returned_ids == expected_ids
  end
end
