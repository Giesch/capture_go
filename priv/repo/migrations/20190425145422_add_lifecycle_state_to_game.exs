defmodule CaptureGo.Repo.Migrations.AddLifecycleStateToGame do
  use Ecto.Migration

  alias CaptureGo.Games.Enums.LifecycleState

  def change do
    LifecycleState.create_type()

    alter table(:games) do
      add :lifecycle_state, LifecycleState.type(), null: false
    end
  end
end
