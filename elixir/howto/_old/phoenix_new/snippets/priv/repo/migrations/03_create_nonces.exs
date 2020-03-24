defmodule MyApp.Repo.Migrations.CreateNonces do
  use Ecto.Migration

  def change do
    create table(:nonces) do
      timestamps()
    end
  end
end
