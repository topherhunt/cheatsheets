def change do
  create table(:users) do
    add :email, :string
    add :uuid, :string
    add :utc_offset, :integer, null: false
    add :size_px, :decimal, precision: 4, scale: 1 # e.g. 100.3
    add :last_signed_in_at, :utc_datetime
    timestamps()
  end

  create index(:users, [:type])
  create unique_index(:users, [:email])
end
