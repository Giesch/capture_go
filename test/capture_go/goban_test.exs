defmodule CaptureGo.GobanTest do
  use ExUnit.Case, async: true

  alias CaptureGo.Goban
  alias CaptureGo.GroupData

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

  test "a stone in the center is captured when it has no liberties" do
    goban = white_wins()
    assert Goban.stone_at(goban, {4, 4}) == {:ok, nil}
    assert goban.prisoners.white == 1
  end

  test "a stone on the side is captured when it has no liberties" do
    goban =
      play_game([
        {:black, {4, 0}},
        {:white, {3, 0}},
        {:black, {8, 8}},
        {:white, {5, 0}},
        {:black, {8, 7}},
        {:white, {4, 1}}
      ])

    assert Goban.stone_at(goban, {4, 0}) == {:ok, nil}
    assert goban.prisoners.white == 1
  end

  test "a stone in the corner is captured when it has no liberties" do
    goban =
      play_game([
        {:black, {0, 0}},
        {:white, {1, 0}},
        {:black, {8, 8}},
        {:white, {0, 1}}
      ])

    assert Goban.stone_at(goban, {0, 0}) == {:ok, nil}
    assert goban.prisoners.white == 1
  end

  test "capturing a stone wins the game" do
    goban = white_wins()
    assert goban.winner == :white
  end

  test "you can't make moves when the game is over" do
    goban = white_wins()
    assert {:error, :game_over} == goban |> Goban.move(:black, {8, 8})
  end

  test "suicide with one stone is illegal" do
    goban =
      play_game([
        {:black, {0, 1}},
        {:white, {8, 8}},
        {:black, {1, 0}}
      ])

    assert Goban.legal?(goban, :white, {0, 0}) == false
    assert {:error, :suicide} == goban |> Goban.move(:white, {0, 0})
  end

  test "suicide with multiple stones is illegal" do
    goban =
      play_game([
        {:black, {0, 1}},
        {:white, {0, 0}},
        {:black, {1, 1}},
        {:white, {8, 8}},
        {:black, {2, 0}}
      ])

    assert Goban.legal?(goban, :white, {1, 0}) == false
    assert {:error, :suicide} == goban |> Goban.move(:white, {1, 0})
  end

  test "if capturing creates a liberty, the move is legal" do
    goban =
      play_game([
        {:black, {1, 0}},
        {:white, {2, 0}},
        {:black, {0, 1}},
        {:white, {1, 1}},
        {:black, {8, 8}},
        {:white, {0, 0}}
      ])

    expected_white_stones = MapSet.new([{0, 0}, {2, 0}, {1, 1}])
    expected_black_stones = MapSet.new([{0, 1}, {8, 8}])

    assert all_stones(goban, :white) == expected_white_stones
    assert all_stones(goban, :black) == expected_black_stones
    assert goban.prisoners.white == 1
    assert goban.prisoners.black == 0
  end

  def white_wins() do
    play_game([
      {:black, {4, 4}},
      {:white, {3, 4}},
      {:black, {0, 0}},
      {:white, {5, 4}},
      {:black, {0, 1}},
      {:white, {4, 3}},
      {:black, {0, 2}},
      {:white, {4, 5}}
    ])
  end

  def play_game(move_list) do
    Enum.reduce(move_list, Goban.new(), fn {color, point}, goban ->
      assert {:ok, goban} = Goban.move(goban, color, point)
      goban
    end)
  end

  def all_stones(%Goban{group_data: group_data}, color) do
    group_data
    |> GroupData.groups()
    |> Enum.filter(fn group -> group.color == color end)
    |> Enum.reduce(MapSet.new(), fn group, stones ->
      MapSet.union(stones, group.stones)
    end)
  end
end
