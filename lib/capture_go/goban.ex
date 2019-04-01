defmodule CaptureGo.Goban do
  @moduledoc """
  A data type for the go board
  """

  import CaptureGo.Color
  alias CaptureGo.Goban
  alias CaptureGo.Goban.StoneGroup
  alias CaptureGo.Goban.Prisoners
  alias CaptureGo.Goban.GroupData

  defstruct board: Map.new(),
            size: 9,
            turn: :black,
            winner: nil,
            prisoners: Prisoners.new(),
            group_data: GroupData.new()

  def new(), do: %Goban{}

  def move(%Goban{} = goban, color, point) when is_color(color) do
    case validate_move(goban, color, point) do
      :ok -> {:ok, place_stone(goban, color, point)}
      error -> error
    end
  end

  def legal?(%Goban{} = goban, color, point) when is_color(color) do
    :ok == validate_move(goban, color, point)
  end

  def stone_at(%Goban{} = goban, point) do
    cond do
      !on_the_board?(goban, point) -> {:error, :off_board}
      true -> {:ok, Map.get(goban.board, point)}
    end
  end

  def groups(%Goban{group_data: group_data}) do
    GroupData.groups(group_data)
  end

  ###########################################

  defp validate_move(goban, color, point) do
    cond do
      goban.turn != color -> {:error, :wrong_turn}
      goban.winner -> {:error, :game_over}
      !on_the_board?(goban, point) -> {:error, :off_board}
      !point_empty?(goban, point) -> {:error, :point_taken}
      is_suicide?(goban, point) -> {:error, :suicide}
      true -> :ok
    end
  end

  defp place_stone(%Goban{} = goban, color, point) do
    %Goban{goban | board: Map.put(goban.board, point, color)}
    |> create_and_connect_group(color, point)
    |> remove_enemy_liberties(color, point)
    |> perform_captures()
    |> win_check()
    |> flip_turn()
  end

  defp create_and_connect_group(%Goban{} = goban, color, point) do
    new_group = StoneGroup.initial(color, point, immediate_liberties(goban, point))
    groups = neighboring_groups(goban, color, point) |> MapSet.put(new_group)
    %Goban{goban | group_data: GroupData.merge(goban.group_data, groups)}
  end

  defp remove_enemy_liberties(%Goban{group_data: group_data} = goban, color, point) do
    groups = neighboring_groups(goban, opposite_color(color), point)
    %Goban{goban | group_data: GroupData.remove_liberty(group_data, groups, point)}
  end

  defp perform_captures(%Goban{} = goban) do
    dead_stones =
      GroupData.groups(goban.group_data)
      |> Enum.filter(fn group -> group.color != goban.turn end)
      |> Enum.filter(&StoneGroup.dead?/1)
      |> Enum.reduce(MapSet.new(), fn dead_group, dead_stones ->
        MapSet.union(dead_group.stones, dead_stones)
      end)

    %Goban{
      goban
      | group_data: GroupData.drop(goban.group_data, dead_stones),
        board: Map.drop(goban.board, dead_stones),
        prisoners: Prisoners.add(goban.prisoners, goban.turn, MapSet.size(dead_stones))
    }
  end

  defp win_check(%Goban{} = goban) do
    %Goban{goban | winner: Prisoners.winner(goban.prisoners)}
  end

  defp flip_turn(%Goban{} = goban) do
    %Goban{goban | turn: opposite_color(goban.turn)}
  end

  defp immediate_liberties(%Goban{} = goban, point) do
    neighboring_points(goban, point)
    |> Enum.filter(fn point -> point_empty?(goban, point) end)
    |> MapSet.new()
  end

  defp point_empty?(%Goban{} = goban, point) do
    {:ok, stone} = stone_at(goban, point)
    stone == nil
  end

  defp is_suicide?(%Goban{} = goban, point) do
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

  defp has_immediate_liberty?(%Goban{} = goban, point) do
    !Enum.empty?(immediate_liberties(goban, point))
  end

  defp only_enemy_neighbors?(%Goban{} = goban, color, point) do
    neighboring_points(goban, point)
    |> Enum.all?(fn point ->
      {:ok, neighbor} = stone_at(goban, point)
      neighbor == opposite_color(color)
    end)
  end

  defp would_capture?(%Goban{} = goban, color, point) do
    enemy_atari_groups =
      neighboring_groups(goban, opposite_color(color), point)
      |> Enum.filter(&StoneGroup.in_atari?/1)

    !Enum.empty?(enemy_atari_groups)
  end

  defp kills_friendly?(%Goban{} = goban, color, point) do
    friendly_atari_groups =
      neighboring_groups(goban, color, point)
      |> Enum.filter(&StoneGroup.in_atari?/1)

    !Enum.empty?(friendly_atari_groups)
  end

  defp neighboring_groups(%Goban{} = goban, color, point) do
    neighbors = neighbors_with_color(goban, color, point)
    GroupData.groups(goban.group_data, neighbors)
  end

  defp neighbors_with_color(%Goban{} = goban, color, point) do
    neighboring_points(goban, point)
    |> Enum.filter(fn point ->
      {:ok, color} == stone_at(goban, point)
    end)
  end

  defp neighboring_points(%Goban{} = goban, point) do
    [up(point), down(point), left(point), right(point)]
    |> Enum.filter(fn point -> on_the_board?(goban, point) end)
  end

  defp up({x, y}), do: {x, y - 1}
  defp down({x, y}), do: {x, y + 1}
  defp left({x, y}), do: {x - 1, y}
  defp right({x, y}), do: {x + 1, y}

  defp on_the_board?(%Goban{} = goban, {x, y}) do
    x >= 0 && x < goban.size && y >= 0 && y < goban.size
  end
end
