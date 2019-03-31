defmodule CaptureGo.StoneGroup do
  @moduledoc """
  Data type for a connected group of stones
  """

  import CaptureGo.Color
  alias CaptureGo.StoneGroup

  defstruct color: nil,
            stones: nil,
            liberties: nil

  def new(color, stones, liberties)
      when is_color(color) do
    %StoneGroup{color: color, stones: stones, liberties: liberties}
  end

  def merge(%StoneGroup{color: color} = a, %StoneGroup{color: color} = b) do
    add_stones(a, b.stones, b.liberties)
  end

  def add_stones(
        %StoneGroup{color: color, stones: stones, liberties: liberties},
        new_stones,
        new_liberties
      ) do
    stones = MapSet.union(stones, new_stones)

    liberties =
      MapSet.union(liberties, new_liberties)
      |> MapSet.difference(stones)

    new(color, stones, liberties)
  end

  def dead?(%StoneGroup{liberties: liberties}) do
    MapSet.size(liberties) == 0
  end

  def in_atari?(%StoneGroup{liberties: liberties}) do
    MapSet.size(liberties) == 1
  end

  def remove_liberty(%StoneGroup{liberties: liberties} = group, liberty) do
    %StoneGroup{group | liberties: MapSet.delete(liberties, liberty)}
  end
end
