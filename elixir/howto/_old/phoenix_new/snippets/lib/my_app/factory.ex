defmodule MyApp.Factory do
  alias MyApp.Data

  def insert_user(params \\ %{}) do
    params = cast(params, [:name, :email, :confirmed_at])
    uuid = random_uuid()

    Data.insert_user!(%{
      name: Map.get(params, :name, "User #{}"),
      email: String.downcase(Map.get(params, :email, "user_#{uuid}@example.com")),
      password: "password",
      confirmed_at: Map.get(params, :confirmed_at, DateTime.utc_now())
    }, :admin)
  end

  def insert_login_try(params \\ %{}) do
    params = cast(params, [:email])
    Data.insert_login_try!(params[:email])
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
