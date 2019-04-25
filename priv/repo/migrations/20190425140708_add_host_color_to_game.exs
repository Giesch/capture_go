defmodule CaptureGo.Repo.Migrations.AddHostColorToGame do
  use Ecto.Migration

  alias CaptureGo.GameRecord.Enums.Color

  def change do
    Color.create_type()

    alter table(:games) do
      add :host_color, Color.type()
    end
  end
end
