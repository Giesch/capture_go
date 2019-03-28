defmodule CaptureGo.GobanTest do
  use ExUnit.Case, async: true

  alias CaptureGo.Goban

  test "a new goban has correct defaults" do
    goban = Goban.new()
    assert goban.turn == :black
    assert goban.winner == nil
    assert goban.board == Map.new()
  end

  test "making a move alternates the turn" do
    assert {:ok, goban} = Goban.new() |> Goban.move(:black, {3, 3})
    assert goban.turn == :white
  end

  @on_board_points [{0, 0}, {8, 8}]
  @off_board_points [{-1, 0}, {0, -1}, {9, 0}, {0, 9}]

  test "only 9x9 points are valid for moves" do
    for point <- @off_board_points do
      assert {:error, :off_board} == Goban.new() |> Goban.move(:black, point)
    end

    for point <- @on_board_points do
      assert {:ok, goban} = Goban.new() |> Goban.move(:black, point)
      assert Goban.stone_at(goban, point) == {:ok, :black}
    end
  end

  test "only 9x9 points are valid for getting coordinates" do
    for point <- @off_board_points do
      assert {:error, :off_board} == Goban.new() |> Goban.stone_at(point)
    end

    for point <- @on_board_points do
      assert {:ok, nil} == Goban.new() |> Goban.stone_at(point)
    end
  end

  test "you can't play a stone on top of another stone" do
    assert {:ok, goban} = Goban.new() |> Goban.move(:black, {3, 3})
    assert {:error, :point_taken} == goban |> Goban.move(:white, {3, 3})
  end

  test "you can't make moves if it's not your turn" do
    goban = Goban.new()
    assert {:error, :wrong_turn} == goban |> Goban.move(:white, {3, 3})
  end

  def white_wins() do
    assert {:ok, goban} = Goban.new() |> Goban.move(:black, {4, 4})
    assert {:ok, goban} = goban |> Goban.move(:white, {3, 4})
    assert {:ok, goban} = goban |> Goban.move(:black, {0, 0})
    assert {:ok, goban} = goban |> Goban.move(:white, {5, 4})
    assert {:ok, goban} = goban |> Goban.move(:black, {0, 1})
    assert {:ok, goban} = goban |> Goban.move(:white, {4, 3})
    assert {:ok, goban} = goban |> Goban.move(:black, {0, 2})
    assert {:ok, goban} = goban |> Goban.move(:white, {4, 5})
    goban
  end

  test "a stone in the center is captured when it has no liberties" do
    goban = white_wins()
    # assert Goban.stone_at(goban, {4, 4}) == {:ok, :dead}
    assert Goban.stone_at(goban, {4, 4}) == {:ok, nil}
    assert goban.whites_prisoners == 1
  end

  test "a stone on the side is captured when it has no liberties" do
    assert {:ok, goban} = Goban.new() |> Goban.move(:black, {4, 0})
    assert {:ok, goban} = goban |> Goban.move(:white, {3, 0})
    assert {:ok, goban} = goban |> Goban.move(:black, {8, 8})
    assert {:ok, goban} = goban |> Goban.move(:white, {5, 0})
    assert {:ok, goban} = goban |> Goban.move(:black, {8, 7})
    assert {:ok, goban} = goban |> Goban.move(:white, {4, 1})

    # assert Goban.stone_at(goban, {4, 0}) == {:ok, :dead}
    assert Goban.stone_at(goban, {4, 0}) == {:ok, nil}
    assert goban.whites_prisoners == 1
  end

  test "a stone in the corner is captured when it has no liberties" do
    assert {:ok, goban} = Goban.new() |> Goban.move(:black, {0, 0})
    assert {:ok, goban} = goban |> Goban.move(:white, {1, 0})
    assert {:ok, goban} = goban |> Goban.move(:black, {8, 8})
    assert {:ok, goban} = goban |> Goban.move(:white, {0, 1})

    # assert Goban.stone_at(goban, {0, 0}) == {:ok, :dead}
    assert Goban.stone_at(goban, {0, 0}) == {:ok, nil}
    assert goban.whites_prisoners == 1
  end

  test "capturing a stone wins the game" do
    goban = white_wins()
    assert goban.winner == :white
  end

  test "you can't make moves when the game is over" do
    goban = white_wins()
    assert {:error, :game_over} == goban |> Goban.move(:black, {8, 8})
  end
end
