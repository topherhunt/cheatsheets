defmodule MyApp.Factory do
  alias MyApp.Accounts

  def insert_user(params \\ %{}) do
    assert_no_keys_except(params, [:email, :password])
    uuid = random_uuid()

    Accounts.insert_user!(%{
      email: params[:email] || "user_#{uuid}@example.com",
      password: params[:password] || uuid
    })
  end

  def random_uuid do
    pool = String.codepoints("ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz123456789")
    Enum.map(1..6, fn _ -> Enum.random(pool) end) |> Enum.join()
  end

  #
  # Internal
  #

  defp assert_no_keys_except(params, allowed_keys) do
    keys = Enum.into(params, %{}) |> Map.keys()

    Enum.each(keys, fn key ->
      unless key in allowed_keys do
        raise "Unexpected key #{inspect(key)}."
      end
    end)
  end
end
