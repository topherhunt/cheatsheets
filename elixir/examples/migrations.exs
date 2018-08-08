def change do
  create table(:users) do
    add :normal_string, :string
    add :non_null_integer, :integer, null: false
    add :a_decimal, :decimal, precision: 4, scale: 1 # e.g. 100.3
    add :normal_date_column, :date
    add :utc_datetime_column, :utc_datetime
    timestamps()
  end

  create index(:users, [:type])
  create unique_index(:users, [:email])
end
