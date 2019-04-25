defmodule CaptureGo.Goban.StoneGroup do
  @moduledoc """
  A data type for a connected group of stones
  """

  import CaptureGo.ColorUtils
  alias CaptureGo.Goban.StoneGroup

  defstruct color: nil,
            stones: nil,
            liberties: nil

  def new(color, stones, liberties) when is_color(color) do
    %StoneGroup{color: color, stones: stones, liberties: liberties}
  end

  def initial(color, stone, liberties) when is_color(color) do
    new(color, MapSet.new([stone]), liberties)
  end

  def merge(%StoneGroup{color: color} = a, %StoneGroup{color: color} = b) do
    add_stones(a, b.stones, b.liberties)
  end

  def add_stones(%StoneGroup{} = group, new_stones, new_liberties) do
    stones = MapSet.union(group.stones, new_stones)

    liberties =
      MapSet.union(group.liberties, new_liberties)
      |> MapSet.difference(stones)

    new(group.color, stones, liberties)
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
