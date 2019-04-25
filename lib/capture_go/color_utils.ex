defmodule CaptureGo.ColorUtils do
  defguard is_color(color) when color in [:black, :white]

  def opposite_color(:black), do: :white
  def opposite_color(:white), do: :black
end
