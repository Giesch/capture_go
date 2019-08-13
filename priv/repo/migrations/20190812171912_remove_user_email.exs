defmodule CaptureGo.Repo.Migrations.RemoveUserEmail do
  use Ecto.Migration

  def change do
    drop unique_index(:users, [:email])

    alter table(:users) do
      remove :email
    end
  end
end
