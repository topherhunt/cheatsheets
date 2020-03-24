defmodule MyApp.Repo.Migrations.CreateLoginTries do
  use Ecto.Migration

  def change do
    create table(:login_tries) do
      add :email, :text
      timestamps()
    end

    create index(:login_tries, [:inserted_at])
  end
end
