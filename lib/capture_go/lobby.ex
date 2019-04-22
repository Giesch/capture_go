defmodule CaptureGo.Lobby do
  @moduledoc """
  A map of game states to game ids.
  """

  alias __MODULE__

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

  def cancel_game(%Lobby{open_games: open_games} = lobby, game_id) do
    if MapSet.member?(open_games, game_id) do
      {:ok, %Lobby{lobby | open_games: MapSet.delete(open_games, game_id)}}
    else
      {:error, :game_closed}
    end
  end

  def end_game(%Lobby{active_games: active_games} = lobby, game_id) do
    if MapSet.member?(active_games, game_id) do
      {:ok, %Lobby{lobby | active_games: MapSet.delete(active_games, game_id)}}
    else
      {:error, :game_inactive}
    end
  end
end
