defmodule CaptureGo.Goban do
  import CaptureGo.Goban.Util

  alias CaptureGo.Goban

  defstruct board: Map.new(), turn: :black, winner: nil
  @opaque t :: %__MODULE__{}

  def new() do
    %Goban{}
  end

  def move(goban, color, point) do
    case validate_move(goban, color, point) do
      {:ok, goban} -> {:ok, place_stone(goban, color, point)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp place_stone(goban, color, point) do
    %Goban{
      goban
      | turn: opposite_color(color),
        board: Map.put(goban.board, point, color)
    }
    |> perform_captures(point)
  end

  def stone_at(goban, point) do
    cond do
      off_the_board?(point) -> {:error, :off_board}
      true -> {:ok, Map.get(goban.board, point)}
    end
  end

  defp validate_move(goban, color, point) do
    cond do
      goban.turn != color -> {:error, :wrong_turn}
      goban.winner -> {:error, :game_over}
      off_the_board?(point) -> {:error, :off_board}
      point_taken?(goban, point) -> {:error, :point_taken}
      true -> {:ok, goban}
    end
  end

  defp off_the_board?({x, y}) do
    x < 0 || x > 8 || y < 0 || y > 8
  end

  defp point_taken?(goban, point) do
    Map.get(goban.board, point) != nil
  end

  defp perform_captures(goban, point) do
    to_check =
      [point | neighboring_points(point)]
      |> Enum.map(fn point ->
        {:ok, color} = stone_at(goban, point)
        {point, color}
      end)
      |> Enum.filter(fn {_point, color} -> is_color?(color) end)

    Enum.reduce(to_check, goban, fn {point, color}, goban ->
      case liberties_check(goban, point) do
        {:alive, _stones, _liberties} ->
          goban

        {:dead, stones} ->
          board =
            Enum.into(goban.board, %{}, fn {point, color} ->
              if MapSet.member?(stones, point) do
                {point, :dead}
              else
                {point, color}
              end
            end)

          %Goban{goban | board: board, winner: opposite_color(color)}
      end
    end)
  end

  # this assumes there's a stone at point
  def liberties_check(goban, point) do
    {:ok, color} = stone_at(goban, point)

    friendly_neighbors = fn point ->
      neighboring_points(point)
      |> Enum.filter(fn point ->
        {:ok, color} == stone_at(goban, point)
      end)
    end

    empty_neighbors = fn point ->
      neighboring_points(point)
      |> Enum.filter(fn point ->
        {:ok, nil} == stone_at(goban, point)
      end)
    end

    traverse_group = fn stones, liberties, to_check, traverse_group ->
      case to_check do
        [] ->
          {stones, liberties}

        [point | to_check] ->
          stones = MapSet.put(stones, point)
          liberties = Enum.into(empty_neighbors.(point), liberties)

          up_next =
            friendly_neighbors.(point)
            |> Enum.filter(fn stone ->
              !MapSet.member?(stones, stone)
            end)

          to_check = up_next ++ to_check

          traverse_group.(stones, liberties, to_check, traverse_group)
      end
    end

    stones = MapSet.new()
    liberties = MapSet.new()
    to_check = [point]
    {stones, liberties} = traverse_group.(stones, liberties, to_check, traverse_group)

    if MapSet.size(liberties) == 0 do
      {:dead, stones}
    else
      {:alive, stones, liberties}
    end
  end

  defp neighboring_points(point) do
    [up(point), down(point), left(point), right(point)]
    |> Enum.filter(fn point -> !off_the_board?(point) end)
  end
end
