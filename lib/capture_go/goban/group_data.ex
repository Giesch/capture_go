defmodule CaptureGo.Goban.GroupData do
  @moduledoc """
  A map of {x, y} tuples to StoneGroups.
  """

  alias CaptureGo.Goban.GroupData
  alias CaptureGo.Goban.StoneGroup

  defstruct points_to_groups: Map.new()

  def new(), do: %GroupData{}

  defp new(points_to_groups) do
    %GroupData{points_to_groups: points_to_groups}
  end

  def groups(%GroupData{points_to_groups: points_to_groups}) do
    points_to_groups |> Map.values() |> MapSet.new()
  end

  def groups(%GroupData{points_to_groups: points_to_groups}, points) do
    points
    |> Enum.map(&Map.get(points_to_groups, &1))
    |> MapSet.new()
  end

  def drop(%GroupData{points_to_groups: points_to_groups}, points) do
    Map.drop(points_to_groups, points) |> new()
  end

  def remove_liberty(group_data, groups, liberty) do
    Enum.reduce(groups, group_data, fn group, group_data ->
      group = StoneGroup.remove_liberty(group, liberty)
      update_group_data(group_data, group)
    end)
  end

  def merge(group_data, groups) do
    update_group_data(group_data, Enum.reduce(groups, &StoneGroup.merge/2))
  end

  defp update_group_data(%GroupData{points_to_groups: points_to_groups}, group) do
    Enum.reduce(group.stones, points_to_groups, fn point, points_to_groups ->
      Map.put(points_to_groups, point, group)
    end)
    |> new()
  end
end
