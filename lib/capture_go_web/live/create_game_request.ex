defmodule CaptureGoWeb.CreateGameRequest do
  import Ecto.Changeset

  alias __MODULE__

  defstruct game_name: ""
  @types %{game_name: :string}

  # the :action field is typically added by Repo calls
  # it's necessary for error_tag to work properly
  def changeset(attrs \\ %{}) do
    {%CreateGameRequest{}, @types}
    |> cast(attrs, [:game_name])
    |> validate_length(:game_name, min: 5, max: 75)
    |> Map.put(:action, :insert)
  end
end
