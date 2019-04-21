defmodule CaptureGo.LobbyIntegrationTest do
  use ExUnit.Case, async: false

  alias CaptureGo.LobbyServer
  alias CaptureGo.GameServer
  alias CaptureGo.TableView
  alias CaptureGo.Goban

  setup do
    start_supervised!(CaptureGo.System)
    :ok
  end

  @game_id "game_id"
  @host "host_token"
  @challenger "challenger_token"
  @password "password"

  test "a new lobby server has no games" do
    assert {:ok, MapSet.new()} == LobbyServer.open_games()
    assert {:ok, MapSet.new()} == LobbyServer.active_games()
  end

  test "open_game adds the game id to open games" do
    assert {:ok, game_server} = LobbyServer.open_game(@game_id, @host)
    assert {:ok, open_games} = LobbyServer.open_games()
    assert MapSet.member?(open_games, @game_id)
  end

  test "begin_game adds the game id to active games" do
    assert {:ok, game_server} = LobbyServer.open_game(@game_id, @host)
    assert {:ok, table_view} = LobbyServer.begin_game(@game_id, @challenger)
    assert {:ok, active_games} = LobbyServer.active_games()
    assert MapSet.member?(active_games, @game_id)
  end

  test "begin_game starts a playable game" do
    assert {:ok, _game_server} = LobbyServer.open_game(@game_id, @host)
    assert {:ok, table_view} = LobbyServer.begin_game(@game_id, @challenger)
    assert %TableView{goban: Goban.new(), state: :game_started} == table_view

    game = GameServer.via_tuple(@game_id)
    assert {:ok, table_view} = GameServer.move(game, @challenger, {3, 3})
    assert %TableView{goban: goban, state: :game_started} = table_view
    assert %Goban{board: %{{3, 3} => :black}} = goban
  end

  test "a game with a password requires a password to begin/challenge" do
    assert {:ok, _game} = LobbyServer.open_game(@game_id, @host, @password)
    result = LobbyServer.begin_game(@game_id, @challenger)
    assert {:error, :unauthorized} = result
  end

  test "the host can cancel an open game" do
    assert {:ok, _game} = LobbyServer.open_game(@game_id, @host, @password)
    assert :ok == LobbyServer.host_cancel(@game_id, @host)

    assert {:ok, open_games} = LobbyServer.open_games()
    refute MapSet.member?(open_games, @game_id)
    assert {:ok, active_games} = LobbyServer.active_games()
    refute MapSet.member?(active_games, @game_id)
  end

  test "a non-host cannot cancel an open game" do
    assert {:ok, _game} = LobbyServer.open_game(@game_id, @host, @password)
    assert {:error, :unauthorized} == LobbyServer.host_cancel(@game_id, @challenger)

    assert {:ok, open_games} = LobbyServer.open_games()
    assert MapSet.member?(open_games, @game_id)
  end
end
