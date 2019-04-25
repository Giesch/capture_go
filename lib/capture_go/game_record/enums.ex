defmodule CaptureGo.GameRecord.Enums do
  import EctoEnum

  # The sides in a go game
  defenum Color, :color, [:black, :white]

  # The states a (persisted) game can be in
  defenum LifecycleState, :lifecycle_state, [
    :started,
    :cancelled,
    :over
  ]
end
