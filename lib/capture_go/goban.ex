defmodule CaptureGo.Goban do
  import CaptureGo.Color
  alias CaptureGo.Goban
  alias CaptureGo.StoneGroup

  defstruct board: Map.new(),
            size: 9,
            turn: :black,
            winner: nil,
            whites_prisoners: 0,
            blacks_prisoners: 0,
            points_to_groups: Map.new(),
            illegal_moves: MapSet.new()

  def new() do
    %Goban{}
  end

  def move(goban, color, point) do
    case validate_move(goban, color, point) do
      {:ok, goban} -> {:ok, place_stone(goban, color, point)}
      {:error, reason} -> {:error, reason}
    end
  end

  def stone_at(goban, point) do
    cond do
      !on_the_board?(goban, point) -> {:error, :off_board}
      true -> {:ok, Map.get(goban.board, point)}
    end
  end

  def illegal?(_goban, _point) do
    false
  end

  ###########################################

  defp validate_move(goban, color, point) do
    cond do
      goban.turn != color -> {:error, :wrong_turn}
      goban.winner -> {:error, :game_over}
      !on_the_board?(goban, point) -> {:error, :off_board}
      !point_empty?(goban, point) -> {:error, :point_taken}
      MapSet.member?(goban.illegal_moves, point) -> {:error, :illegal_move}
      true -> {:ok, goban}
    end
  end

  defp place_stone(%Goban{} = goban, color, point) do
    adjacent_enemy_groups = neighboring_groups(goban, opposite_color(color), point)

    new_group =
      StoneGroup.new(
        color,
        MapSet.new([point]),
        immediate_liberties(goban, point)
      )

    full_group =
      neighboring_groups(goban, color, point)
      |> Enum.reduce(new_group, fn neighboring_group, group ->
        StoneGroup.merge(group, neighboring_group)
      end)

    goban =
      Enum.reduce(adjacent_enemy_groups, goban, fn enemy_group, goban ->
        enemy_group = StoneGroup.remove_liberty(enemy_group, point)
        update_points_to_groups(goban, enemy_group)
      end)

    %Goban{goban | board: Map.put(goban.board, point, color)}
    |> update_points_to_groups(full_group)
    |> perform_captures()
    |> win_check()
    |> flip_turn()
    |> put_illegal_moves()
  end

  defp update_points_to_groups(
         %Goban{points_to_groups: points_to_groups} = goban,
         %StoneGroup{stones: stones} = group
       ) do
    points_to_groups =
      Enum.reduce(stones, points_to_groups, fn point, points_to_groups ->
        Map.put(points_to_groups, point, group)
      end)

    %Goban{goban | points_to_groups: points_to_groups}
  end

  defp immediate_liberties(goban, point) do
    neighboring_points(goban, point)
    |> Enum.filter(fn point ->
      point_empty?(goban, point)
    end)
    |> MapSet.new()
  end

  defp neighbors_with_color(goban, color, point) do
    neighboring_points(goban, point)
    |> Enum.filter(fn point ->
      {:ok, color} == stone_at(goban, point)
    end)
  end

  defp neighboring_groups(goban, color, point) do
    neighbors_with_color(goban, color, point)
    |> Enum.map(fn neighbor ->
      Map.get(goban.points_to_groups, neighbor)
    end)
    |> MapSet.new()
  end

  defp flip_turn(goban) do
    %Goban{goban | turn: opposite_color(goban.turn)}
  end

  defp put_illegal_moves(%Goban{} = goban) do
    # TODO this doesn't account for adding a liberty
    # TODO check if it will capture?
    # TODO public api for this, so UI can display

    illegal_moves = goban.illegal_moves
    # Map.values(points_to_groups)
    # |> MapSet.new()
    # |> Enum.filter(&StoneGroup.in_atari?/1)
    # # filter will_capture?
    # |> Enum.filter(fn group ->
    #   group.color == color
    # end)
    # |> Enum.reduce(MapSet.new(), fn atari_group, illegal_points ->
    #   MapSet.union(atari_group.liberties, illegal_points)
    # end)

    %Goban{goban | illegal_moves: illegal_moves}
  end

  defp perform_captures(%Goban{} = goban) do
    dead_stones =
      goban.points_to_groups
      |> Map.values()
      |> MapSet.new()
      |> Enum.filter(fn group -> group.color != goban.turn end)
      |> Enum.filter(&StoneGroup.dead?/1)
      |> Enum.reduce(MapSet.new(), fn dead_group, dead_stones ->
        MapSet.union(dead_group.stones, dead_stones)
      end)

    %Goban{
      goban
      | points_to_groups: Map.drop(goban.points_to_groups, dead_stones),
        board: Map.drop(goban.board, dead_stones)
    }
    |> add_prisoners(MapSet.size(dead_stones))
  end

  defp add_prisoners(%Goban{} = goban, amount) do
    case goban.turn do
      :white ->
        %Goban{goban | whites_prisoners: goban.whites_prisoners + amount}

      :black ->
        %Goban{goban | blacks_prisoners: goban.blacks_prisoners + amount}
    end
  end

  defp win_check(goban) do
    cond do
      goban.blacks_prisoners > 0 ->
        %Goban{goban | winner: :black}

      goban.whites_prisoners > 0 ->
        %Goban{goban | winner: :white}

      true ->
        goban
    end
  end

  defp point_empty?(goban, point) do
    {:ok, stone} = stone_at(goban, point)
    stone == nil
  end

  defp neighboring_points(goban, point) do
    [up(point), down(point), left(point), right(point)]
    |> Enum.filter(fn point -> on_the_board?(goban, point) end)
  end

  defp up({x, y}), do: {x, y - 1}
  defp down({x, y}), do: {x, y + 1}
  defp left({x, y}), do: {x - 1, y}
  defp right({x, y}), do: {x + 1, y}

  defp on_the_board?(goban, {x, y}) do
    x >= 0 && x < goban.size && y >= 0 && y < goban.size
  end
end
