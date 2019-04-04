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

  # TODO: maintain a set of groups to make this is unnecessary
  def groups(%GroupData{points_to_groups: points_to_groups}) do
    for {_point, group} <- points_to_groups,
        into: MapSet.new(),
        do: group
  end

  def groups(%GroupData{points_to_groups: points_to_groups}, points) do
    for point <- points,
        into: MapSet.new(),
        do: Map.get(points_to_groups, point)
  end

  def drop(%GroupData{points_to_groups: points_to_groups}, points) do
    Map.drop(points_to_groups, points) |> new()
  end

  def remove_liberty(group_data, groups, liberty) do
    Enum.reduce(groups, group_data, fn group, group_data ->
      group
      |> StoneGroup.remove_liberty(liberty)
      |> update_group_data(group_data)
    end)
  end

  def merge(group_data, groups) do
    groups
    |> Enum.reduce(&StoneGroup.merge/2)
    |> update_group_data(group_data)
  end

  defp update_group_data(group, %GroupData{points_to_groups: points_to_groups}) do
    put_group = fn point, map -> Map.put(map, point, group) end
    Enum.reduce(group.stones, points_to_groups, put_group) |> new()
  end
end
