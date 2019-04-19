defmodule CaptureGo.Lobby do
  @moduledoc """
  A map of game states to game ids.
  """

  alias CaptureGo.Lobby

  defstruct open_games: MapSet.new(),
            active_games: MapSet.new()

  def new() do
    %Lobby{}
  end

  def open_game(%Lobby{} = lobby, game_id) do
    cond do
      MapSet.member?(lobby.open_games, game_id) -> {:error, :game_open}
      MapSet.member?(lobby.active_games, game_id) -> {:error, :game_active}
      true -> add_open_game(lobby, game_id)
    end
  end

  defp add_open_game(%Lobby{} = lobby, game_id) do
    open_games = MapSet.put(lobby.open_games, game_id)
    {:ok, %Lobby{lobby | open_games: open_games}}
  end

  def begin_game(%Lobby{} = lobby, game_id) do
    cond do
      MapSet.member?(lobby.active_games, game_id) -> {:error, :game_active}
      !MapSet.member?(lobby.open_games, game_id) -> {:error, :not_found}
      true -> make_game_active(lobby, game_id)
    end
  end

  defp make_game_active(%Lobby{} = lobby, game_id) do
    lobby = %Lobby{
      lobby
      | open_games: MapSet.delete(lobby.open_games, game_id),
        active_games: MapSet.put(lobby.active_games, game_id)
    }

    {:ok, lobby}
  end

  def close_game(%Lobby{} = lobby, game_id) do
    open = MapSet.delete(lobby.open_games, game_id)
    active = MapSet.delete(lobby.active_games, game_id)
    lobby = %Lobby{lobby | open_games: open, active_games: active}
    {:ok, lobby}
  end
end
