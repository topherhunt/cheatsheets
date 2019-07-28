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

  def random_uuid, do: Nanoid.generate(8)

  #
  # Internal
  #

  defp assert_no_keys_except(params, allowed_keys) do
    keys = Enum.into(params, %{}) |> Map.keys()
    unexpected_key = Enum.find(keys, & &1 not in allowed_keys)
    if unexpected_key, do: raise "Unexpected key: #{inspect(unexpected_key)}."
  end
end
