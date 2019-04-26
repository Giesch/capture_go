defmodule CaptureGo.Repo.Migrations.HashGamePasswords do
  use Ecto.Migration

  def change do
    alter table(:games) do
      add :password_hash, :string
      remove :password
    end
  end
end
