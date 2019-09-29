def change do
  create table(:users) do
    # Other on_delete options: nothing, nilify_all, restrict
    add :org_id, references(:orgs, on_delete: :delete_all)
    add :name, :string
    add :age_years, :integer, null: false
    add :birth_date, :date
    add :last_logged_in_at, :utc_datetime
    add :height_inches, :decimal, precision: 4, scale: 1 # e.g. 100.3
    add :project_ids, {:array, :integer}, null: false # array of integers (int[])
    timestamps()
  end

  create index(:users, [:type])
  create unique_index(:users, [:email])
end
