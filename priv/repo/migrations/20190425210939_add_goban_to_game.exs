defmodule CaptureGo.Repo.Migrations.AddGobanToGame do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :goban, :binary, null: false
    end
  end
end
