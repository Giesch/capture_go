defmodule CaptureGo.Goban do
  @moduledoc """
  A data type for the go board
  """

  import CaptureGo.ColorUtils
  alias CaptureGo.Goban
  alias CaptureGo.Goban.StoneGroup
  alias CaptureGo.Goban.GroupData

  defstruct board: Map.new(),
            size: 9,
            turn: :black,
            winner: nil,
            prisoners: %{black: 0, white: 0},
            group_data: GroupData.new()

  def new(), do: %Goban{}

  def move(%Goban{} = goban, color, point) when is_color(color) do
    case validate_move(goban, color, point) do
      :ok -> {:ok, place_stone(goban, color, point)}
      {:error, _reason} = failure -> failure
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

  ##################
  # Move procedure
  #

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

  defp perform_captures(%Goban{turn: turn, prisoners: prisoners} = goban) do
    dead_enemy? = fn group -> group.color != turn && StoneGroup.dead?(group) end
    collect_stones = fn group, stones -> MapSet.union(group.stones, stones) end

    dead_stones =
      GroupData.groups(goban.group_data)
      |> Stream.filter(dead_enemy?)
      |> Enum.reduce(MapSet.new(), collect_stones)

    %Goban{
      goban
      | group_data: GroupData.drop(goban.group_data, dead_stones),
        board: Map.drop(goban.board, dead_stones),
        prisoners: Map.update!(prisoners, turn, &(&1 + MapSet.size(dead_stones)))
    }
  end

  defp win_check(%Goban{prisoners: prisoners} = goban) do
    has_prisoners? = fn color -> Map.get(prisoners, color) > 0 end
    %Goban{goban | winner: Enum.find([:black, :white], has_prisoners?)}
  end

  defp flip_turn(%Goban{} = goban) do
    %Goban{goban | turn: opposite_color(goban.turn)}
  end

  ####################
  # Suicide checking
  # The predicates rely on the order they are called in is_suicide?/2
  #

  defp is_suicide?(%Goban{} = goban, point) do
    cond do
      has_immediate_liberty?(goban, point) -> false
      would_capture?(goban, goban.turn, point) -> false
      only_enemy_neighbors?(goban, goban.turn, point) -> true
      kills_friendly?(goban, goban.turn, point) -> true
      true -> false
    end
  end

  defp has_immediate_liberty?(%Goban{} = goban, point) do
    !Enum.empty?(immediate_liberties(goban, point))
  end

  defp would_capture?(%Goban{} = goban, color, point) do
    neighboring_groups(goban, opposite_color(color), point)
    |> Enum.any?(&StoneGroup.in_atari?/1)
  end

  defp only_enemy_neighbors?(%Goban{} = goban, color, point) do
    is_enemy? = fn point ->
      stone_at(goban, point) == {:ok, opposite_color(color)}
    end

    neighboring_points(goban, point) |> Enum.all?(is_enemy?)
  end

  # this relies on has_immediate_liberty?/2 having been called
  defp kills_friendly?(%Goban{} = goban, color, point) do
    neighboring_groups(goban, color, point)
    |> Enum.all?(&StoneGroup.in_atari?/1)
  end

  ########
  # Misc
  #

  defp immediate_liberties(%Goban{} = goban, point) do
    neighboring_points(goban, point)
    |> Enum.filter(&point_empty?(goban, &1))
    |> MapSet.new()
  end

  defp point_empty?(%Goban{} = goban, point) do
    {:ok, nil} == stone_at(goban, point)
  end

  defp neighboring_groups(%Goban{} = goban, color, point) do
    neighbors = neighbors_with_color(goban, color, point)
    GroupData.groups(goban.group_data, neighbors)
  end

  defp neighbors_with_color(%Goban{} = goban, color, point) do
    our_color? = fn point -> {:ok, color} == stone_at(goban, point) end
    neighboring_points(goban, point) |> Enum.filter(our_color?)
  end

  defp neighboring_points(%Goban{} = goban, {x, y}) do
    [{x, y - 1}, {x, y + 1}, {x - 1, y}, {x + 1, y}]
    |> Enum.filter(&on_the_board?(goban, &1))
  end

  defp on_the_board?(%Goban{size: size}, {x, y}) do
    x >= 0 && x < size && y >= 0 && y < size
  end

  ###############
  # Persistence
  #

  @behaviour Ecto.Type

  @impl Ecto.Type
  def type, do: :binary

  @impl Ecto.Type
  def cast(binary) when is_binary(binary) do
    case :erlang.binary_to_term(binary) do
      %Goban{} = goban -> {:ok, goban}
      _ -> :error
    end
  end

  def cast(_), do: :error

  @impl Ecto.Type
  def load(binary) when is_binary(binary) do
    case :erlang.binary_to_term(binary) do
      %Goban{} = goban -> {:ok, goban}
      _ -> :error
    end
  end

  def load(_), do: :error

  @impl Ecto.Type
  def dump(%Goban{} = goban) do
    {:ok, :erlang.term_to_binary(goban)}
  end

  def dump(_), do: :error
end
