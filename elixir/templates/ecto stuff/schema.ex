defmodule Vanilla.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "samples" do
    belongs_to :user, MyApp.User
    has_many :subsamples, MyApp.Subsample
    has_many :kittens, through: [:subsamples, :kitten]

    field :name, :string
    field :height_cm, :integer
    field :approved, :boolean
    field :collected_at, :utc_datetime
    field :expiration_date, :date
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :name, :height_cm, :approved, :collected_at])
    |> validate_required([:user_id, :name])
    |> validate_inclusion(:type, ["admin", "faculty", "student"])
    |> unique_constraint(:name)
    |> assoc_constraint(:user)
    |> put_password_hash_if_valid(struct)
  end

  #
  # Filters
  #

  def apply_filters(starting_query, filters) do
    Enum.reduce(filters, starting_query, fn {k, v}, query -> filter(query, k, v) end)
  end

  def filter(query, :id, id), do: where(query, [p], p.id == ^id)
  def filter(query, :uuid, uuid), do: where(query, [p], p.uuid == ^uuid)
  def filter(query, :project, proj), do: where(query, [p], p.project_id == ^proj.id)
  def filter(query, :order, :id), do: order_by(query, [p], asc: p.id)
  def filter(query, :order, :name), do: order_by(query, [p], asc: p.name)
  def filter(query, :order, :newest), do: order_by(query, [p], desc: p.id)
end
