defmodule Zb.Interview do
  use Zb.Web, :model

  schema "interviews" do
    belongs_to :user, Zb.User # indexed
    field :position, :integer
    field :password, :string, virtual: true
    field :password_hash, :string
    field :eligible_for_voting, :boolean
    field :woke_at_time, Timex.Ecto.Time # for a :time field
    field :due_on_date, Timex.Ecto.Date
    field :completed_at, Timex.Ecto.DateTime # UTC
    has_many :vote_taggings, Zb.VoteTagging
    has_many :tags, through: [:vote_taggings, :tag]
    timestamps()
  end

  def admin_changeset(struct, params \\ %{}) do
    struct
      |> cast(params, [:type, :email, :password, :full_name])
      |> validate_required([:type, :email])
      |> validate_inclusion(:type, ["admin", "faculty", "student"])
      |> unique_constraint(:email)
      |> assoc_constraint(:user)
      |> assoc_constraint(:question)
      |> put_password_hash_if_valid(struct)
  end

  def interviewee_changeset(struct, params \\ %{}) do
    struct
      |> cast(params, [:recording])
      |> validate_required([:recording])
      |> put_change(:completed_at, Timex.now)
  end
end
