defmodule CaptureGo.LobbyTest do
  use ExUnit.Case, async: true

  alias CaptureGo.Lobby

  @game_id "my game"

  test "a new lobby has no games" do
    lobby = Lobby.new()
    assert Enum.empty?(lobby.open_games)
    assert Enum.empty?(lobby.active_games)
  end

  test "opening a game adds it to open games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert Enum.member?(lobby.open_games, @game_id)
  end

  test "opening an open game is an error" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert {:error, :game_open} == Lobby.open_game(lobby, @game_id)
  end

  test "opening an active game is an error" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert {:error, :game_active} == Lobby.open_game(lobby, @game_id)
  end

  test "beginning a game moves it to active games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert Enum.member?(lobby.active_games, @game_id)
    refute Enum.member?(lobby.open_games, @game_id)
  end

  test "beginning a nonexistent game is an error" do
    lobby = Lobby.new()
    assert {:error, :not_found} == Lobby.begin_game(lobby, @game_id)
  end

  test "beginning an active game is an error" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert {:error, :game_active} == Lobby.begin_game(lobby, @game_id)
  end

  test "closing a game removes it from open games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.close_game(lobby, @game_id)
    refute Enum.member?(lobby.open_games, @game_id)
    refute Enum.member?(lobby.active_games, @game_id)
  end

  test "closing a game removes it from active games" do
    lobby = Lobby.new()
    assert {:ok, lobby} = Lobby.open_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.begin_game(lobby, @game_id)
    assert {:ok, lobby} = Lobby.close_game(lobby, @game_id)
    refute Enum.member?(lobby.open_games, @game_id)
    refute Enum.member?(lobby.active_games, @game_id)
  end
end
