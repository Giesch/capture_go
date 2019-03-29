defmodule CaptureGo.Color do
  defguard is_color(color) when color == :black or color == :white

  def opposite_color(:black), do: :white
  def opposite_color(:white), do: :black
end
