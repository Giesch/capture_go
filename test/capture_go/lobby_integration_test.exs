defmodule CaptureGo.LobbyIntegrationTest do
  use ExUnit.Case, async: false

  alias CaptureGo.LobbyServer
  alias CaptureGo.GameServer
  alias CaptureGo.Goban
  alias CaptureGo.LobbyGame
  alias CaptureGo.Table

  @host_token "host_token"
  @challenger "challenger_token"
  @password "password"

  @game_name "game name"
  @host_name "host name"

  def make_lobby_game(game_id) do
    LobbyGame.new(game_id, @game_name, @host_name, DateTime.utc_now())
  end

  setup do
    game_id = make_ref()
    lobby_game = make_lobby_game(game_id)
    [game_id: game_id, lobby_game: lobby_game]
  end

  test "open_game adds the game id to open games",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, game_server} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:ok, lobby} = LobbyServer.lobby()
    assert Map.has_key?(lobby.open_games, game_id)
  end

  @tag :pending
  test "open game starts a game server",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, game_server} = LobbyServer.open_game(lobby_game, @host_token)
    _via_tuple = GameServer.via_tuple(game_id)
  end

  test "begin_game adds the game id to active games",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, game_server} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:ok, table} = LobbyServer.begin_game(game_id, @challenger)
    assert {:ok, lobby} = LobbyServer.lobby()
    assert Map.has_key?(lobby.active_games, game_id)
  end

  @tag :pending
  test "begin game fails gracefully if the game server is missing" do
  end

  test "begin_game starts a playable game",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game_server} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:ok, table} = LobbyServer.begin_game(game_id, @challenger)
    assert %Table{goban: goban, state: :game_started} = table
    assert Goban.new() == goban

    game = GameServer.via_tuple(game_id)
    assert {:ok, table} = GameServer.move(game, @challenger, {3, 3})
    assert %Table{goban: goban, state: :game_started} = table
    assert %Goban{board: %{{3, 3} => :black}} = goban
  end

  test "a game with a password requires a password to begin/challenge",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game} = LobbyServer.open_game(lobby_game, @host_token, @password)
    result = LobbyServer.begin_game(game_id, @challenger)
    assert {:error, :unauthorized} = result
  end

  test "the host can cancel an open game",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game} = LobbyServer.open_game(lobby_game, @host_token)
    assert :ok == LobbyServer.host_cancel(game_id, @host_token)

    assert {:ok, lobby} = LobbyServer.lobby()
    refute Map.has_key?(lobby.open_games, game_id)
    refute Map.has_key?(lobby.active_games, game_id)
  end

  test "a non-host cannot cancel an open game",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:error, :unauthorized} == LobbyServer.host_cancel(game_id, @challenger)

    assert {:ok, lobby} = LobbyServer.lobby()
    assert Map.has_key?(lobby.open_games, game_id)
  end

  # TODO: how to mock an inconsistent state between game and lobby?
  # ie challenge succeeds, but game is not active in the lobby
  # that should get a different error than this
  test "a started game cannot be host-cancelled",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:ok, _table} = LobbyServer.begin_game(game_id, @challenger)
    assert {:error, _reason} = LobbyServer.host_cancel(game_id, @host_token)
  end

  test "an active game can be ended",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:ok, _table} = LobbyServer.begin_game(game_id, @challenger)
    assert :ok == LobbyServer.end_game(game_id)

    assert {:ok, lobby} = LobbyServer.lobby()
    refute Map.has_key?(lobby.active_games, game_id)
    refute Map.has_key?(lobby.open_games, game_id)
  end

  test "an unstarted game cannot be ended",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:error, :game_inactive} == LobbyServer.end_game(game_id)
  end

  test "winning a game removes it from the lobby server's active games",
       %{game_id: game_id, lobby_game: lobby_game} do
    assert {:ok, _game_server} = LobbyServer.open_game(lobby_game, @host_token)
    assert {:ok, table} = LobbyServer.begin_game(game_id, @challenger)
    assert %Table{goban: goban, state: :game_started} = table
    assert Goban.new() == goban
    assert {:ok, lobby} = LobbyServer.lobby()
    assert Map.has_key?(lobby.active_games, game_id)

    game = GameServer.via_tuple(game_id)
    assert {:ok, table} = GameServer.move(game, @challenger, {0, 0})
    assert {:ok, table} = GameServer.move(game, @host_token, {1, 0})
    assert {:ok, table} = GameServer.move(game, @challenger, {8, 8})
    assert {:ok, table} = GameServer.move(game, @host_token, {0, 1})

    assert %Table{state: :game_over} = table
    assert {:ok, lobby} = LobbyServer.lobby()
    refute Map.has_key?(lobby.active_games, game_id)
  end
end
