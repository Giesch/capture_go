defmodule CaptureGo.Goban do
  import CaptureGo.Color
  alias CaptureGo.Goban
  alias CaptureGo.StoneGroup
  alias CaptureGo.Prisoners

  defstruct board: Map.new(),
            size: 9,
            turn: :black,
            winner: nil,
            points_to_groups: Map.new(),
            prisoners: Prisoners.new()

  def new() do
    %Goban{}
  end

  def move(goban, color, point) do
    case validate_move(goban, color, point) do
      {:ok, goban} -> {:ok, place_stone(goban, color, point)}
      failure -> failure
    end
  end

  def stone_at(goban, point) do
    cond do
      !on_the_board?(goban, point) -> {:error, :off_board}
      true -> {:ok, Map.get(goban.board, point)}
    end
  end

  def legal?(goban, color, point) do
    case validate_move(goban, color, point) do
      {:ok, _} -> true
      _ -> false
    end
  end

  ###########################################

  defp validate_move(goban, color, point) do
    cond do
      goban.turn != color -> {:error, :wrong_turn}
      goban.winner -> {:error, :game_over}
      !on_the_board?(goban, point) -> {:error, :off_board}
      !point_empty?(goban, point) -> {:error, :point_taken}
      is_suicide?(goban, point) -> {:error, :suicide}
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
        board: Map.drop(goban.board, dead_stones),
        prisoners: Prisoners.add(goban.prisoners, goban.turn, MapSet.size(dead_stones))
    }
  end

  defp win_check(goban) do
    winner =
      Enum.find([:black, :white], fn color ->
        Map.get(goban.prisoners, color) > 0
      end)

    %Goban{goban | winner: winner}
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

  defp is_suicide?(goban, point) do
    cond do
      has_immediate_liberty?(goban, point) ->
        false

      would_capture?(goban, goban.turn, point) ->
        false

      only_enemy_neighbors?(goban, goban.turn, point) ->
        true

      kills_friendly?(goban, goban.turn, point) ->
        true

      true ->
        false
    end
  end

  # These predicates rely on the order they are called in is_suicide?/2

  defp has_immediate_liberty?(goban, point) do
    !Enum.empty?(immediate_liberties(goban, point))
  end

  defp only_enemy_neighbors?(goban, color, point) do
    neighboring_points(goban, point)
    |> Enum.all?(fn point ->
      {:ok, neighbor} = stone_at(goban, point)
      neighbor == opposite_color(color)
    end)
  end

  defp would_capture?(goban, color, point) do
    enemy_atari_groups =
      neighboring_groups(goban, opposite_color(color), point)
      |> Enum.filter(&StoneGroup.in_atari?/1)

    !Enum.empty?(enemy_atari_groups)
  end

  defp kills_friendly?(goban, color, point) do
    friendly_atari_groups =
      neighboring_groups(goban, color, point)
      |> Enum.filter(&StoneGroup.in_atari?/1)

    !Enum.empty?(friendly_atari_groups)
  end
end
