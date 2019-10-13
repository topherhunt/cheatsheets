defmodule MyApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> require_password_if_absent()
    |> put_hashed_password()
  end

  def require_password_if_absent(changeset) do
    if get_field(changeset, :password_hash) do
      changeset
    else
      validate_required(changeset, [:password])
    end
  end

  def put_hashed_password(changeset) do
    new_password = get_change(changeset, :password)

    if changeset.valid? && new_password do
      put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(new_password))
    else
      changeset
    end
  end

  #
  # Filters
  #

  def apply_filters(starting_query, filters) do
    Enum.reduce(filters, starting_query, fn {k, v}, query -> filter(query, k, v) end)
  end

  def filter(query, :id, id), do: where(query, [u], u.id == ^id)
  def filter(query, :email, email), do: where(query, [u], u.email == ^email)
end
