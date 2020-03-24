defmodule MyApp.Data.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "users" do
    field :email, :string
    field :session_token, :string
    field :last_visit_date, :date
    timestamps()
  end

  # For internal use. These fields should not be directly controllable by end users.
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :session_token, :last_visit_date])
    |> downcase_email()
    |> set_session_token()
    |> validate_required([:email, :session_token])
    |> unique_constraint(:email)
  end

  defp downcase_email(changeset) do
    email = get_field(changeset, :email) || ""
    downcased = String.downcase(email)

    if email != downcased do
      put_change(changeset, :email, downcased)
    else
      changeset
    end
  end

  defp set_session_token(changeset) do
    if get_field(changeset, :session_token) == nil do
      put_change(changeset, :session_token, Nanoid.generate(20))
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

  def filter(query, :id, id), do: where(query, [t], t.id == ^id)
  def filter(query, :email, e), do: where(query, [u], u.email == ^String.downcase(e))
  def filter(query, :session_token, st), do: where(query, [t], t.session_token == ^st)
end
