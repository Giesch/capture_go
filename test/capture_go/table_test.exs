defmodule CaptureGo.TableTest do
  use ExUnit.Case, async: true

  alias CaptureGo.Table

  @host_token "host_token"
  @challenger_token "challenger_token"
  @password "password"

  test "a new table has the awaiting challenger state" do
    table = Table.new(@host_token)
    assert table.state == :table_open
  end

  test "a game can be created with a password" do
    table = Table.new(@host_token, password: @password)
    assert table.password == @password
  end

  test "an open table can be challenged" do
    table = Table.new(@host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    assert table.challenger_token == @challenger_token
    assert table.challenger_color == :black
  end

  test "a non-open table cannot be challenged" do
    table = Table.new(@host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    expected = {:error, {:invalid_for_state, :game_started}}
    assert Table.challenge(table, @challenger_token, :black) == expected
  end

  test "if the game has a password, it is required for a challenge" do
    table = Table.new(@host_token, password: @password)
    assert {:error, :unauthorized} = Table.challenge(table, @challenger_token, :black)
  end

  test "the host can cancel a their game before it starts" do
    table = Table.new(@host_token)
    assert table.state == :table_open
    assert {:ok, table} = Table.host_cancel(table, @host_token)
    assert table.state == :host_cancelled
  end

  test "only the host can cancel their game" do
    table = Table.new(@host_token)
    assert table.state == :table_open
    assert {:error, :unauthorized} = Table.host_cancel(table, @challenger_token)
  end

  test "a started game cannot be cancelled" do
    table = Table.new(@host_token)
    assert {:ok, table} = Table.challenge(table, @challenger_token, :black)
    assert table.state == :game_started
    expected = {:error, {:invalid_for_state, :game_started}}
    assert Table.host_cancel(table, @host_token) == expected
  end
end
