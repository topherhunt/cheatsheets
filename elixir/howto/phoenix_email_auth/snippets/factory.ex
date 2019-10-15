defmodule Worldviews.Factory do
  alias Worldviews.Data

  def insert_user(params \\ %{}) do
    params = cast(params, [:email])
    uuid = random_uuid()
    email = params[:email] || "user_#{uuid}@example.com"
    Data.insert_user!(%{email: email})
  end

  def random_uuid, do: Nanoid.generate(8)

  #
  # Internal
  #

  defp cast(params, allowed_keys) do
    params = Enum.into(params, %{})
    unexpected_key = Map.keys(params) |> Enum.find(& &1 not in allowed_keys)
    if unexpected_key, do: raise "Unexpected key: #{inspect(unexpected_key)}."
    params
  end
end
