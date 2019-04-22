defmodule CaptureGo.Lobby do
  @moduledoc """
  A store of lobby-related game metadata.
  Games are categorized as open or active, and keyed by game id.
  """

  alias __MODULE__
  alias CaptureGo.LobbyGame

  # maps of game id to LobbyGame
  defstruct open_games: Map.new(),
            active_games: Map.new()

  def new() do
    %Lobby{}
  end

  def open_game(%Lobby{} = lobby, %LobbyGame{} = game) do
    cond do
      Map.has_key?(lobby.open_games, game.id) -> {:error, :game_open}
      Map.has_key?(lobby.active_games, game.id) -> {:error, :game_active}
      true -> add_open_game(lobby, game)
    end
  end

  defp add_open_game(%Lobby{} = lobby, %LobbyGame{} = game) do
    open_games = Map.put(lobby.open_games, game.id, game)
    {:ok, %Lobby{lobby | open_games: open_games}}
  end

  def begin_game(%Lobby{} = lobby, game_id) do
    cond do
      Map.has_key?(lobby.active_games, game_id) -> {:error, :game_active}
      !Map.has_key?(lobby.open_games, game_id) -> {:error, :not_found}
      true -> make_game_active(lobby, game_id)
    end
  end

  defp make_game_active(%Lobby{} = lobby, game_id) do
    game = Map.get(lobby.open_games, game_id)

    lobby = %Lobby{
      lobby
      | open_games: Map.delete(lobby.open_games, game_id),
        active_games: Map.put(lobby.active_games, game_id, game)
    }

    {:ok, lobby}
  end

  def cancel_game(%Lobby{open_games: open_games} = lobby, game_id) do
    if Map.has_key?(open_games, game_id) do
      open_games = Map.delete(open_games, game_id)
      {:ok, %Lobby{lobby | open_games: open_games}}
    else
      {:error, :game_closed}
    end
  end

  def end_game(%Lobby{active_games: active_games} = lobby, game_id) do
    if Map.has_key?(active_games, game_id) do
      active_games = Map.delete(active_games, game_id)
      {:ok, %Lobby{lobby | active_games: active_games}}
    else
      {:error, :game_inactive}
    end
  end
end
