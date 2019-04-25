defmodule CaptureGo.Repo.Migrations.AddHostColorToGame do
  use Ecto.Migration

  alias CaptureGo.Games.Enums.Color

  def change do
    Color.create_type()

    alter table(:games) do
      add :host_color, Color.type(), null: false
    end
  end
end
