defmodule EyeTest.Data.Sample do
  use Ecto.Schema
  import Ecto.Changeset
  require Ecto.Query
  alias Ecto.Query, as: Q
  alias EyeTest.Data
  alias EyeTest.Repo

  schema "samples" do
    belongs_to :user, Data.User
    field :name, :string
    field :cm_from_screen, :integer
    timestamps()
  end

  #
  # Public
  #

  def get(id, filt \\ []), do: get_by(Keyword.merge([id: id], filt))

  def get!(id, filt \\ []), do: get_by!(Keyword.merge([id: id], filt))

  def get_by(filt), do: __MODULE__ |> filter(filt) |> Repo.first()

  def get_by!(filt), do: __MODULE__ |> filter(filt) |> Repo.first!()

  def all(filt \\ []), do: __MODULE__ |> filter(filt) |> Repo.all()

  def count(filt \\ []), do: __MODULE__ |> filter(filt) |> Repo.count()

  def insert(params), do: new_changeset(params) |> Repo.insert()

  def insert!(params), do: insert(params) |> Repo.ensure_success()

  def update(struct, params), do: changeset(struct, params) |> Repo.update()

  def update!(struct, params), do: update(struct, params) |> Repo.ensure_success()

  def delete!(struct), do: Repo.delete!(struct)

  # TODO: Require certain filters so I can't nuke the whole db
  def delete_all!(filt), do: __MODULE__ |> filter(filt) |> Repo.delete_all()

  def new_changeset(params \\ %{}), do: changeset(%__MODULE__{}, params)

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:user_id, :name, :cm_from_screen])
    |> validate_required([:user_id, :name, :cm_from_screen])
  end

  #
  # Filters
  #

  def filter(starting_query, filters) do
    Enum.reduce(filters, starting_query, fn {k, v}, query -> filter(query, k, v) end)
  end

  def filter(query, :id, id), do: Q.where(query, [l], l.id == ^id)
  def filter(query, :user, user), do: Q.where(query, [l], l.user_id == ^user.id)
  def filter(query, :order, :name), do: Q.order_by(query, [l], asc: l.name)
end
