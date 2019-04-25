defmodule CaptureGo.GameTableTest do
  use ExUnit.Case, async: true

  alias CaptureGo.GameTable

  @game_id "my_game"
  @host_token "host_token"
  @challenger_token "challenger_token"
  @password "password"

  test "a new table has the awaiting challenger state" do
    table = GameTable.new(@game_id, @host_token)
    assert table.state == :table_open
  end

  test "a game can be created with a password" do
    table = GameTable.new(@game_id, @host_token, @password)
    assert table.password == @password
  end

  test "an open table can be challenged" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert table.challenger_token == @challenger_token
    assert table.player_colors[@challenger_token] == :black
    assert table.player_colors[@host_token] == :white
  end

  test "a non-open table cannot be challenged" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    expected = {:error, {:invalid_for_state, :game_started}}
    assert GameTable.challenge(table, @challenger_token, :black) == expected
  end

  test "if the game has a password, it is required for a challenge" do
    table = GameTable.new(@game_id, @host_token, @password)
    assert {:error, :unauthorized} = GameTable.challenge(table, @challenger_token, :black)
  end

  test "if the game has a password, it can be challenged with the password" do
    table = GameTable.new(@game_id, @host_token, @password)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black, @password)
  end

  test "the host can cancel a their game before it starts" do
    table = GameTable.new(@game_id, @host_token)
    assert table.state == :table_open
    assert {:ok, table} = GameTable.host_cancel(table, @host_token)
    assert table.state == :host_cancelled
  end

  test "only the host can cancel their game" do
    table = GameTable.new(@game_id, @host_token)
    assert table.state == :table_open
    assert {:error, :unauthorized} = GameTable.host_cancel(table, @challenger_token)
  end

  test "a started game cannot be cancelled" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    expected = {:error, {:invalid_for_state, :game_started}}
    assert GameTable.host_cancel(table, @host_token) == expected
  end

  test "players can make moves on a started game" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:ok, table} = GameTable.move(table, @challenger_token, {2, 2})
    assert {:ok, table} = GameTable.move(table, @host_token, {6, 2})
    assert table.goban.board[{2, 2}] == :black
    assert table.goban.board[{6, 2}] == :white
  end

  test "players cannot make moves in a game they're not part of" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:error, :unauthorized} == GameTable.move(table, "sneaky", {2, 2})
  end

  test "players can only make moves for their color" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:error, :wrong_turn} == GameTable.move(table, @host_token, {2, 2})
  end

  test "winning ends the game" do
    table = GameTable.new(@game_id, @host_token)
    assert {:ok, table} = GameTable.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:ok, table} = GameTable.move(table, @challenger_token, {0, 0})
    assert {:ok, table} = GameTable.move(table, @host_token, {1, 0})
    assert {:ok, table} = GameTable.move(table, @challenger_token, {8, 8})
    assert {:ok, table} = GameTable.move(table, @host_token, {0, 1})
    assert table.goban.winner == :white
    assert table.state == :game_over
  end
end
