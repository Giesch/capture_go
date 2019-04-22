defmodule CaptureGo.LobbyTest do
  use ExUnit.Case, async: true

  alias CaptureGo.Lobby
  alias CaptureGo.LobbyGame

  @game_id "my_game_id"
  @game_name "my game"
  @host_name "me"
  @lobby_game LobbyGame.new(@game_id, @game_name, @host_name)

  test "a new lobby has no games" do
    lobby = Lobby.new()
    assert Enum.empty?(lobby.open_games)
    assert Enum.empty?(lobby.active_games)
  end

  test "opening a game adds it to open games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert Map.has_key?(lobby.open_games, @game_id)
  end

  test "opening an open game is an error" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:error, :game_open} == Lobby.open_game(lobby, @lobby_game)
  end

  test "opening an active game is an error" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert {:error, :game_active} == Lobby.open_game(lobby, @lobby_game)
  end

  test "beginning a game moves it to active games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert Map.has_key?(lobby.active_games, @game_id)
    refute Map.has_key?(lobby.open_games, @game_id)
  end

  test "beginning a nonexistent game is an error" do
    lobby = Lobby.new()
    assert {:error, :not_found} == Lobby.begin_game(lobby, @game_id)
  end

  test "beginning an active game is an error" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert {:error, :game_active} == Lobby.begin_game(lobby, @game_id)
  end

  test "cancelling an open game removes it from open games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:ok, lobby} = Lobby.cancel_game(lobby, @game_id)
    refute Map.has_key?(lobby.open_games, @game_id)
    refute Map.has_key?(lobby.active_games, @game_id)
  end

  test "a game that has begun cannot be cancelled" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert Map.has_key?(lobby.active_games, @game_id)
    assert {:error, :game_closed} = Lobby.cancel_game(lobby, @game_id)
  end

  test "ending an active game removes it from active games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @lobby_game)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.end_game(lobby, @game_id)
    refute Map.has_key?(lobby.open_games, @game_id)
    refute Map.has_key?(lobby.active_games, @game_id)
  end

  test "an inactive game cannot be ended" do
    lobby = Lobby.new()
    assert {:error, :game_inactive} == Lobby.end_game(lobby, @lobby_game)
  end
end
