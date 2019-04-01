defmodule CaptureGo.Prisoners do
  @moduledoc """
  A map of captures by color.
  Color is the color of the capturer, not the capturee.
  """

  import CaptureGo.Color
  alias CaptureGo.Prisoners

  defstruct black: 0, white: 0

  def new(), do: %Prisoners{}

  def add(prisoners, color, amount) when is_color(color) do
    Map.update!(prisoners, color, fn p -> p + amount end)
  end

  def winner(prisoners) do
    Enum.find([:black, :white], fn color -> Map.get(prisoners, color) > 0 end)
  end
end
