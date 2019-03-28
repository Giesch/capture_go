defmodule CaptureGo.Goban.Util do
  def opposite_color(:black), do: :white
  def opposite_color(:white), do: :black

  def is_color?(:black), do: true
  def is_color?(:white), do: true
  def is_color?(_), do: false

  def up({x, y}), do: {x, y - 1}
  def down({x, y}), do: {x, y + 1}
  def left({x, y}), do: {x - 1, y}
  def right({x, y}), do: {x + 1, y}
end
