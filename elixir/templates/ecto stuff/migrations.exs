def change do
  create table(:users) do
    add :org_id, references(:orgs, on_delete: :delete_all)
    add :name, :string
    add :age_years, :integer, null: false
    add :height_inches, :decimal, precision: 4, scale: 1 # e.g. 100.3
    add :retirement_date, :date
    add :last_yawned_at, :utc_datetime
    timestamps()
  end

  create index(:users, [:type])
  create unique_index(:users, [:email])
end
