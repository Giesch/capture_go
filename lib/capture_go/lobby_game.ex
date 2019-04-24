defmodule CaptureGo.LobbyGame do
  @moduledoc """
  A data type for the game data to display in the lobby
  """

  alias __MODULE__

  defstruct id: nil,
            game_name: nil,
            host_name: nil,
            challenger_name: nil,
            created_at: nil

  def new(game_id, game_name, host_name, created_at) do
    %LobbyGame{
      id: game_id,
      game_name: game_name,
      host_name: host_name,
      created_at: created_at
    }
  end
end
