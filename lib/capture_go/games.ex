defmodule CaptureGo.Games do
  @moduledoc """
  The games context.
  Handles both persistence and the 'meta' rules about the lifecycle of a game.
  """

  alias CaptureGo.Games.Game
  alias CaptureGo.Repo

  def create_game(attrs \\ %{}) do
    %Game{}
    |> Game.changeset(attrs)
    |> Repo.insert()
  end
end
