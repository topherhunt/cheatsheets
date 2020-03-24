defmodule MyApp.Data.LoginTry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "login_tries" do
    field :email, :string
    timestamps()
  end

  def admin_changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email])
    |> validate_required([:email])
  end
end
