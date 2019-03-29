defmodule CaptureGo.Goban do
  alias CaptureGo.Goban
  import CaptureGo.Color

  defstruct board: Map.new(),
            size: 9,
            turn: :black,
            winner: nil,
            whites_prisoners: 0,
            blacks_prisoners: 0

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
      !on_the_board?(goban, point) -> {:error, :off_board}
      true -> {:ok, Map.get(goban.board, point)}
    end
  end

  defp validate_move(goban, color, point) do
    cond do
      goban.turn != color -> {:error, :wrong_turn}
      goban.winner -> {:error, :game_over}
      !on_the_board?(goban, point) -> {:error, :off_board}
      point_taken?(goban, point) -> {:error, :point_taken}
      true -> {:ok, goban}
    end
  end

  defp on_the_board?(goban, {x, y}) do
    x >= 0 && x < goban.size && y >= 0 && y < goban.size
  end

  defp point_taken?(goban, point) do
    Map.get(goban.board, point) != nil
  end

  defp perform_captures(goban, point) do
    to_check =
      [point | neighboring_points(goban, point)]
      |> Enum.map(fn point ->
        {:ok, color} = stone_at(goban, point)
        {point, color}
      end)
      |> Enum.filter(fn {_point, color} -> is_color(color) end)

    goban = mark_captures(to_check, goban)
    {board, whites_prisoners, blacks_prisoners} = remove_captures(goban)

    %Goban{
      goban
      | board: board,
        whites_prisoners: whites_prisoners,
        blacks_prisoners: blacks_prisoners
    }
  end

  defp mark_captures(to_check, goban) do
    Enum.reduce(to_check, goban, fn {point, color}, goban ->
      case liberties_check(goban, point) do
        {:alive, _stones, _liberties} ->
          goban

        {:dead, stones} ->
          board =
            goban.board
            |> Enum.map(fn
              # TODO this is unnecessary i guess
              {point, {:dead, color}} ->
                {point, {:dead, color}}

              {point, color} ->
                if MapSet.member?(stones, point) do
                  {point, {:dead, color}}
                else
                  {point, color}
                end
            end)
            |> Enum.into(%{})

          %Goban{goban | board: board, winner: opposite_color(color)}
      end
    end)
  end

  defp remove_captures(goban) do
    Enum.reduce(
      goban.board,
      {goban.board, goban.whites_prisoners, goban.blacks_prisoners},
      fn intersection, {board, whites_prisoners, blacks_prisoners} = results ->
        case intersection do
          {point, {:dead, :white}} ->
            {Map.delete(board, point), whites_prisoners, blacks_prisoners + 1}

          {point, {:dead, :black}} ->
            {Map.delete(board, point), whites_prisoners + 1, blacks_prisoners}

          _ ->
            results
        end
      end
    )
  end

  # this assumes there's a stone at point
  def liberties_check(goban, point) do
    {:ok, color} = stone_at(goban, point)

    friendly_neighbors = fn point ->
      neighboring_points(goban, point)
      |> Enum.filter(fn point ->
        {:ok, color} == stone_at(goban, point)
      end)
    end

    empty_neighbors = fn point ->
      neighboring_points(goban, point)
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

  defp neighboring_points(goban, point) do
    [up(point), down(point), left(point), right(point)]
    |> Enum.filter(fn point -> on_the_board?(goban, point) end)
  end

  def up({x, y}), do: {x, y - 1}
  def down({x, y}), do: {x, y + 1}
  def left({x, y}), do: {x - 1, y}
  def right({x, y}), do: {x + 1, y}
end
