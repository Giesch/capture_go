defmodule CaptureGo.Repo.Migrations.AddLifecycleStateToGame do
  use Ecto.Migration

  alias CaptureGo.Kifu.Enums.LifecycleState

  def change do
    LifecycleState.create_type()

    alter table(:games) do
      add :lifecycle_state, LifecycleState.type()
    end
  end
end
