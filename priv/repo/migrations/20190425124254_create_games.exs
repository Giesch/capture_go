defmodule CaptureGo.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games) do
      add :name, :string, null: false
      add :password, :string

      add :host_id,
          references(:users, on_delete: :nothing),
          null: false

      add :challenger_id,
          references(:users, on_delete: :nothing),
          null: false

      timestamps()
    end

    create index(:games, [:host_id])
    create index(:games, [:challenger_id])
  end
end
