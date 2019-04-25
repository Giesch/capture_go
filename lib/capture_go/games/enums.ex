defmodule CaptureGo.Games.Enums do
  import EctoEnum

  # The sides in a go game
  defenum Color, :color, [:black, :white]

  # The states a game can be in
  defenum LifecycleState, :lifecycle_state, [
    # the initial state, waiting for a second player
    :open,
    # game in progress
    :started,
    # game ended before finding a second player
    :cancelled,
    # game ended after finding a second player
    :over
  ]
end
