defmodule CaptureGo.TableTest do
  use ExUnit.Case, async: true

  alias CaptureGo.Table

  @game_id "my_game"
  @host_token "host_token"
  @challenger_token "challenger_token"
  @password "password"

  test "a new table has the awaiting challenger state" do
    table = Table.new(@game_id, @host_token)
    assert table.state == :table_open
  end

  test "a game can be created with a password" do
    table = Table.new(@game_id, @host_token, password: @password)
    assert table.password == @password
  end

  test "an open table can be challenged" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert table.challenger_token == @challenger_token
    assert table.player_colors[@challenger_token] == :black
    assert table.player_colors[@host_token] == :white
  end

  test "a non-open table cannot be challenged" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    expected = {:error, {:invalid_for_state, :game_started}}
    assert Table.challenge(table, @challenger_token, :black) == expected
  end

  test "if the game has a password, it is required for a challenge" do
    table = Table.new(@game_id, @host_token, password: @password)
    assert {:error, :unauthorized} = Table.challenge(table, @challenger_token, :black)
  end

  test "the host can cancel a their game before it starts" do
    table = Table.new(@game_id, @host_token)
    assert table.state == :table_open
    assert {:ok, table} = Table.host_cancel(table, @host_token)
    assert table.state == :host_cancelled
  end

  test "only the host can cancel their game" do
    table = Table.new(@game_id, @host_token)
    assert table.state == :table_open
    assert {:error, :unauthorized} = Table.host_cancel(table, @challenger_token)
  end

  test "a started game cannot be cancelled" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    expected = {:error, {:invalid_for_state, :game_started}}
    assert Table.host_cancel(table, @host_token) == expected
  end

  test "players can make moves on a started game" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:ok, table} = Table.move(table, @challenger_token, {2, 2})
    assert {:ok, table} = Table.move(table, @host_token, {6, 2})
    assert table.goban.board[{2, 2}] == :black
    assert table.goban.board[{6, 2}] == :white
  end

  test "players cannot make moves in a game they're not part of" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:error, :unauthorized} == Table.move(table, "sneaky", {2, 2})
  end

  test "players can only make moves for their color" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:error, :wrong_turn} == Table.move(table, @host_token, {2, 2})
  end

  test "winning ends the game" do
    table = Table.new(@game_id, @host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert {:ok, table} = Table.move(table, @challenger_token, {0, 0})
    assert {:ok, table} = Table.move(table, @host_token, {1, 0})
    assert {:ok, table} = Table.move(table, @challenger_token, {8, 8})
    assert {:ok, table} = Table.move(table, @host_token, {0, 1})
    assert table.goban.winner == :white
    assert table.state == :game_over
  end
end
